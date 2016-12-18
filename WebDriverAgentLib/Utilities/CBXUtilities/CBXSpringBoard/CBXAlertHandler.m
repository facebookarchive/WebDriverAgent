
#import "CBXAlertHandler.h"
#import "CBXSpringBoardAlert.h"
#import "CBXSpringBoardAlerts.h"
#import "CBXGestureCommands.h"

#import "XCUIElement.h"
#import "XCUIApplication.h"
#import "XCApplicationQuery.h"
#import "XCElementSnapshot.h"
#import "XCUIElement+FBWebDriverAttributes.h"

#import "FBApplication.h"
#import "FBSession.h"
#import "FBLogger.h"

typedef enum : NSUInteger {
    SpringBoardAlertHandlerIgnoringAlerts = 0,
    SpringBoardAlertHandlerNoAlert,
    SpringBoardAlertHandlerDismissedAlert,
    SpringBoardAlertHandlerUnrecognizedAlert,
    SpringBoardAlertHandlerUnableToDismiss
} SpringBoardAlertHandlerResult;

@interface CBXAlertHandler ()

- (BOOL)shouldDismissAlertsAutomatically;
- (BOOL)tapAlertButtonWithFrame:(CGRect)frame;
- (SpringBoardAlertHandlerResult)handleAlert;

@end

@implementation CBXAlertHandler

- (instancetype)init_private {
    if ((self = [super init])) {
        XCUIApplication *app = [FBSession activeSession].application;
        _alert = [FBAlert alertWithApplication:app];
    }
    return self;
}

+ (instancetype)alertHandler {
    static CBXAlertHandler *_handler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _handler = [CBXAlertHandler new];
        /*
        _springBoard = [[CBXSpringBoard alloc]
                        initPrivateWithPath:nil
                        bundleID:@"com.apple.springboard"];
        [[_springBoard applicationQuery] elementBoundByIndex:0];
        [_springBoard resolve];
         */
    });
    return _handler;
}

- (BOOL)shouldDismissAlertsAutomatically {
    // TODO Provide a launch argument or route to disable the automatic dismiss.
    return YES;
}

- (void)handleSpringboardAlertsOrThrow {
    @synchronized (self) {
        if (![self shouldDismissAlertsAutomatically]) { return; }
        
        SpringBoardAlertHandlerResult current = SpringBoardAlertHandlerNoAlert;

        // There are fewer than 20 kinds of SpringBoard alerts.
        NSUInteger maxTries = 20;
        NSUInteger try = 0;

        current = [self handleAlert];

        while (current != SpringBoardAlertHandlerNoAlert && try < maxTries) {
            current = [self handleAlert];
            if (current == SpringBoardAlertHandlerUnrecognizedAlert) {
                break;
            }
            try = try + 1;
        }

        if (try == maxTries || current == SpringBoardAlertHandlerUnrecognizedAlert) {
            NSString *alertTitle = nil;
            NSArray *alertButtonTitles = @[];

            if ([self.alert isPresent]) {
                XCUIElement *alertElement = [self.alert alertElement];
                
                alertTitle = self.alert.text;
                XCUIElementQuery *query = [alertElement descendantsMatchingType:XCUIElementTypeButton];
                NSArray<XCUIElement *> *buttons = [query allElementsBoundByIndex];

                NSMutableArray *mutable = [NSMutableArray arrayWithCapacity:buttons.count];

                for (XCUIElement *button in buttons) {
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
    XCUIApplication *currentApp = [FBSession activeSession].application;
    FBAlert *alert = [FBAlert alertWithApplication:currentApp];

    // There is not alert.
    if (![alert isPresent]) {
        return SpringBoardAlertHandlerNoAlert;
    }

    // .label is the title for English and German.  Hopefully for others too.
    NSString *title = alert.text;
    CBXSpringBoardAlert *springBoardAlert = [[CBXSpringBoardAlerts shared] alertMatchingTitle:title];

    // We don't know about this alert.
    if (!springBoardAlert) {
        return SpringBoardAlertHandlerUnrecognizedAlert;
    }

    // Alert is now gone? It can happen...
    if (![alert isPresent]) {
        return SpringBoardAlertHandlerNoAlert;
    }

    NSError *e;
    if (springBoardAlert.shouldAccept) {
        [alert acceptWithError:&e];
    } else {
        [alert dismissWithError:&e];
    }
    if (e) {
        [FBLogger logFmt:@"Error handling alert (%@): %@", alert.text, e];
        return SpringBoardAlertHandlerUnableToDismiss;
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
        if (![self.alert isPresent]) {
            return SpringBoardDismissAlertNoAlert;
        } else {
            NSError *e;
            BOOL success = [self.alert pressButtonTitled:title error:&e];

            SpringBoardDismissAlertResult result;
            if (success) {
                result = SpringBoardDismissAlertDismissedAlert;
            } else {
                [FBLogger logFmt:@"Error dissmissing button titled '%@': %@", title, e];
                result = SpringBoardDismissAlertDismissTouchFailed;
            }
            return result;
        }
    }
}

@end
