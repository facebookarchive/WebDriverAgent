
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
        _handler = [[CBXAlertHandler alloc] init_private];
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

            if ([self.alert springboardAlertIsPresent]) {
                XCUIElement *alertElement = [self.alert springboardAlertElement];
                
                alertTitle = self.alert.springBoardAlertText;
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
    // There is not alert.
    if (![self.alert springboardAlertIsPresent]) {
        return SpringBoardAlertHandlerNoAlert;
    }

    // .label is the title for English and German.  Hopefully for others too.
    NSString *title = self.alert.springBoardAlertText;
    CBXSpringBoardAlert *springBoardAlert = [[CBXSpringBoardAlerts shared] alertMatchingTitle:title];

    // We don't know about this alert.
    if (!springBoardAlert) {
        return SpringBoardAlertHandlerUnrecognizedAlert;
    }

    // Alert is now gone? It can happen...
    // I am skeptical - CF
    if (![self.alert springboardAlertIsPresent]) {
        return SpringBoardAlertHandlerNoAlert;
    }

    NSError *e;
    if (springBoardAlert.shouldAccept) {
        [self.alert springboardAcceptWithError:&e];
    } else {
        [self.alert springboardDismissWithError:&e];
    }
    if (e) {
        [FBLogger logFmt:@"Error handling alert (%@): %@", self.alert.springBoardAlertText, e];
        return SpringBoardAlertHandlerUnableToDismiss;
    }

    return SpringBoardAlertHandlerDismissedAlert;
}

- (SpringBoardDismissAlertResult)dismissSpringboardAlertByTappingButtonWithTitle:(NSString *)title {
    @synchronized (self) {
        if (![self.alert springboardAlertIsPresent]) {
            return SpringBoardDismissAlertNoAlert;
        } else {
            NSError *e;
            BOOL success = [self.alert pressSpringboardButtonTitled:title error:&e];

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
