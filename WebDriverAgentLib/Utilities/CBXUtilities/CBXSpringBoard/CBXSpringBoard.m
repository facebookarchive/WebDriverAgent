
#import "CBXSpringBoard.h"
#import "CBXSpringBoardAlert.h"
#import "CBXSpringBoardAlerts.h"

#import "XCUIElement.h"
#import "XCUIApplication.h"
#import "XCApplicationQuery.h"
#import "XCElementSnapshot.h"
#import "XCUIElement+FBWebDriverAttributes.h"

#import "CBXGestureCommands.h"

typedef enum : NSUInteger {
    SpringBoardAlertHandlerIgnoringAlerts = 0,
    SpringBoardAlertHandlerNoAlert,
    SpringBoardAlertHandlerDismissedAlert,
    SpringBoardAlertHandlerUnrecognizedAlert
} SpringBoardAlertHandlerResult;

@interface CBXSpringBoard ()

- (BOOL)shouldDismissAlertsAutomatically;
- (BOOL)tapAlertButtonWithFrame:(CGRect)frame;
- (SpringBoardAlertHandlerResult)handleAlert;

@end

@implementation CBXSpringBoard

- (instancetype)initPrivateWithPath:(id)arg1 bundleID:(id)arg2 {
    self = [super initPrivateWithPath:arg1 bundleID:arg2];
    if (self) {
        // Please keep.  There were implementations that required ivars.
        // Interacting with SpringBoard is a WIP.
    }
    return self;
}

+ (instancetype)application {
    static CBXSpringBoard *_springBoard;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _springBoard = [[CBXSpringBoard alloc]
                        initPrivateWithPath:nil
                        bundleID:@"com.apple.springboard"];
        [[_springBoard applicationQuery] elementBoundByIndex:0];
        [_springBoard resolve];
    });
    return _springBoard;
}

- (XCUIElement *)queryForAlert {
    @synchronized (self) {
        XCUIElement *alert = nil;

        XCUIElementQuery *query = [self descendantsMatchingType:XCUIElementTypeAlert];
        NSArray <XCUIElement *> *elements = [query allElementsBoundByIndex];

        if ([elements count] != 0) {
            alert = elements[0];
        }
        return alert;
    }
}

- (BOOL)shouldDismissAlertsAutomatically {
    // TODO Provide a launch argument or route to disable the automatic dismiss.
    return YES;
}

- (void)handleAlertsOrThrow {

    @synchronized (self) {

        if (![self shouldDismissAlertsAutomatically]) { return; }

        SpringBoardAlertHandlerResult current = SpringBoardAlertHandlerNoAlert;

        // There are fewer than 20 kinds of SpringBoard alerts.
        NSUInteger maxTries = 20;
        NSUInteger try = 0;

        current = [self handleAlert];

        while(current != SpringBoardAlertHandlerNoAlert && try < maxTries) {
            current = [self handleAlert];
            if (current == SpringBoardAlertHandlerUnrecognizedAlert) {
                break;
            }
            try = try + 1;
        }

        if (try == maxTries || current == SpringBoardAlertHandlerUnrecognizedAlert) {
            XCUIElement *alert = nil;
            NSString *alertTitle = nil;
            NSArray *alertButtonTitles = @[];

            alert = [self queryForAlert];

            if (alert && alert.exists) {
                alertTitle = alert.label;
                XCUIElementQuery *query = [alert descendantsMatchingType:XCUIElementTypeButton];
                NSArray<XCUIElement *> *buttons = [query allElementsBoundByIndex];

                NSMutableArray *mutable = [NSMutableArray arrayWithCapacity:buttons.count];

                for(XCUIElement *button in buttons) {
                    if (button.exists) {
                        NSString *name = button.label;
                        if (name) {
                            [mutable addObject:name];
                        }
                    }
                }
                alertButtonTitles = [NSArray arrayWithArray:mutable];
            }

            NSString *message = @"A SpringBoard alert is blocking test execution and it cannot be dismissed.";
            @throw [NSException exceptionWithName:@"InvalidDeviceStateException"
                                           reason:message
                                         userInfo:@{
                                               @"title" : alertTitle ?: [NSNull null],
                                               @"buttons" : alertButtonTitles,
                                               @"tries" : @(maxTries)
                                               }];
        }
    }
}

// If something goes wrong, SpringBoardAlertHandlerNoAlert is returned.
// This method is not protected by a lock!  It should only be called by
// handleAlertsOrThrow
- (SpringBoardAlertHandlerResult)handleAlert {

    XCUIElement *alert = [self queryForAlert];

    // There is not alert.
    if (!alert || !alert.exists) {
        return SpringBoardAlertHandlerNoAlert;
    }

    // .label is the title for English and German.  Hopefully for others too.
    NSString *title = alert.label;
    CBXSpringBoardAlert *springBoardAlert = [[CBXSpringBoardAlerts shared] alertMatchingTitle:title];

    // We don't know about this alert.
    if (!springBoardAlert) {
        return SpringBoardAlertHandlerUnrecognizedAlert;
    }

    XCUIElement *button = nil;
    NSString *mark = springBoardAlert.defaultDismissButtonMark;

    // Alert is now gone? It can happen...
    if (!alert.exists) {
        return SpringBoardAlertHandlerNoAlert;
    }

    button = alert.buttons[mark];
    // Resolve before asking if the button exists.
    [button resolve];

    // A button with the expected title does not exist.
    // It probably changed after an iOS update.
    if (!button || !button.exists) {
        button = nil;
    }

    // Use the default accept/deny button, but only if we recognize this alert.
    if (!button) {

        if (!alert.exists) {
            return SpringBoardAlertHandlerNoAlert;
        }

        XCUIElementQuery *query = [alert descendantsMatchingType:XCUIElementTypeButton];
        NSArray<XCUIElement *> *buttons = [query allElementsBoundByIndex];

        if ([buttons count] == 0) {
            return SpringBoardAlertHandlerNoAlert;
        }

        if (springBoardAlert.shouldAccept) {
            button = buttons.lastObject;
        } else {
            button = buttons.firstObject;
        }
    }

    // Resolve before asking if the button exists.
    [button resolve];

    if (!button || !button.exists) {
        return SpringBoardAlertHandlerNoAlert;
    }

    // There are cases where the button does not respond to wdFrame.
    // I cannot explain why, but it was happening during development.
    CGRect frame;
    if (![button respondsToSelector:@selector(wdFrame)]) {
        frame = [button frame];
    } else {
        frame = [button wdFrame];
    }

    BOOL success = [self tapAlertButtonWithFrame:frame];

    if (!success) {
        return SpringBoardAlertHandlerNoAlert;
    }

    return SpringBoardAlertHandlerDismissedAlert;
}

- (BOOL)tapAlertButtonWithFrame:(CGRect)frame {
    @synchronized (self) {

        // There are cases where we cannot find a hitpoint.
        if (frame.origin.x <= 0.0 || frame.origin.y <= 0.0) {
            return NO;
        }

        // This could also be done with [button tap].
        //
        // However, the system seems more stable if we use our touch gesture.
        double x = CGRectGetMinX(frame) + (CGRectGetWidth(frame)/2.0);
        double y = CGRectGetMinY(frame) + (CGRectGetHeight(frame)/2.0);
        
        NSDictionary *specifiers = @{@"coordinate" : @{ @"x" : @(x), @"y" : @(y)}};
        BOOL success = [CBXGestureCommands handleTouch:specifiers options:@{}];
        
        
        if (success) {
            // There is one alert workflow that is very problematic:
            //
            // PhotoRoll
            //
            // 1. Trigger the alert
            // 2. Alert appears
            // 3. Alert is automatically dismissed
            // 3. Photo Roll is animated on behind the alert
            // 4. Next gesture or query triggers an alert query
            //
            // The AXServer crashes, then the AUT crashes, and then DeviceAgent
            // performs the gesture or query on the SpringBoard.  For example, if
            // the gesture was a touch to Cancel the Photo Roll, the Newstand app
            // would open because that is the App Icon at the position of the
            // of the Cancel touch.  Sleeping after the dismiss definitely
            // reduced the frequency of crashes - they still happened.
            //
            // The AUT crash was caused by IImagePickerViewController which has a
            // history of crashing in situations like this.
            //
            // After days device and simulator testing, I settled on 1.0 second.
            // If there is no sleep or the sleep is too short the AXServer can
            // disconnect which can cause the DeviceAgent to fail: crashes,
            // TestPlan exits, etc.
            //
            // We will need to see if this value needs to be adjusted for different
            // environments e.g. CI, XTC, Simulators, etc.
            //
            // We prefer stability over speed.
            NSTimeInterval interval = 1.0;
            NSDate *until = [[NSDate date] dateByAddingTimeInterval:interval];
            [[NSRunLoop mainRunLoop] runUntilDate:until];
        }
        return success;
    }
}

- (SpringBoardDismissAlertResult)dismissAlertByTappingButtonWithTitle:(NSString *)title {
    @synchronized (self) {
        XCUIElement *alert = [self queryForAlert];

        if (!alert) {
            return SpringBoardDismissAlertNoAlert;
        } else {
            XCUIElement *button = alert.buttons[title];
            [button resolve];

            if (!button.exists) {
                return SpringBoardDismissAlertNoMatchingButton;
            }

            // There are cases where the button does not respond to wdFrame.
            CGRect frame;
            if (![button respondsToSelector:@selector(wdFrame)]) {
                frame = [button frame];
            } else {
                frame = [button wdFrame];
            }

            BOOL success = [self tapAlertButtonWithFrame:frame];

            SpringBoardDismissAlertResult result;
            if (success) {
                result = SpringBoardDismissAlertDismissedAlert;
            } else {
                result = SpringBoardDismissAlertDismissTouchFailed;
            }
            return result;
        }
    }
}

@end
