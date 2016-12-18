
#import "CBXTextInputFirstResponderProvider.h"
#import "CBXGestureCommands.h"
#import "CBXAlertHandler.h"
#import "CBXCoordinate.h"

#import "FBApplication.h"
#import "FBKeyboard.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBErrorBuilder.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "FBMacros.h"
#import "FBLogger.h"
#import "FBElementTypeTransformer.h"
#import "FBAlert.h"

#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBTyping.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "XCUIElement+CBXCoordinateGestures.h"

@implementation CBXGestureCommands
#pragma mark - <FBCommandHandler>

static NSDictionary <NSString *, NSString *>*gestureMap;

typedef id<FBResponsePayload>(^elementOrCBXCoordinateHandler)(XCUIApplication *app, XCUIElement *element, CBXCoordinate *coord);
typedef id<FBResponsePayload>(^noResultHandlerBlock)(void);

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gestureMap = @{
                       @"touch" : @"handleTouch:options:",
                       @"touch_and_hold" : @"handleTouchAndHold:options:",
                       @"enter_text" : @"handleEnterText:options:",
                       @"clear_text" : @"handleClearText:options:",
                       @"double_tap" : @"handleDoubleTap:options:",
                       @"two_finger_tap" : @"handleDoubleTap:options:",
                       @"drag" : @"handleDrag:options:",
                       @"pinch" : @"handlePinch:options:",
                       @"rotate" : @"handleRotate:options:"
                       };
    });
}

+ (NSArray *)routes
{
    return
    @[
      [[FBRoute POST:CBXRoute(@"/gesture")].withCBXSession respondWithTarget:self
                                                                      action:@selector(handleGesture:)],
      [[FBRoute POST:CBXRoute(@"/dismiss-springboard-alerts")].withCBXSession respondWithTarget:self
                                                                                         action:@selector(handleSpringboardAlerts:)],
      [[FBRoute POST:CBXRoute(@"/dismiss-springboard-alert")].withCBXSession respondWithTarget:self
                                                                                         action:@selector(handleSpringboardAlert:)],
      ];
}

- (id<FBResponsePayload>)handleSpringboardAlert:(FBRouteRequest *)request {
    NSString *buttonTitle = request.arguments[@"button"];
    
    if (!buttonTitle) {
        return CBXResponseWithException([NSException exceptionWithName:@"InvalidArgumentException"
                                                                reason:@"Request body is missing required key: 'button'"
                                                              userInfo:@{@"received_body" : request.arguments ?: @{}}]);
    }
    
    FBAlert *alert = [CBXAlertHandler alertHandler].alert;
    if (alert.isPresent) {
        NSError *e;
        BOOL success = [alert pressButtonTitled:buttonTitle error:&e];
        if (success) {
            return CBXResponseWithJSON(@{ @"status" : @"success" });
        } else {
            if (e) {
                [FBLogger logFmt:@"Error dismissing alert with title '%@': %@", buttonTitle, e];
            }
            return CBXResponseWithErrorFormat(@"Error dismissing alert with title '%@': %@", buttonTitle, e);
        }
    } else {
        return CBXResponseWithJSON(@{@"error": @"There is no SpringBoard alert."});
    }
}

- (id<FBResponsePayload>)handleSpringboardAlerts:(FBRouteRequest *)request {
     [[CBXAlertHandler alertHandler] handleSpringboardAlertsOrThrow];
     return CBXResponseWithJSON(@{ @"status" : @"no alerts" });
}

- (id<FBResponsePayload>)getElementOrCoordinate:(NSDictionary *)specifiers
                                        handler:(elementOrCBXCoordinateHandler)handler
                                noResultHandler:(noResultHandlerBlock)noResultHandler {
    XCUIApplication *app = [FBSession activeSession].application;
    if ([specifiers hasKey:@"uuid"]) {
        FBElementCache *elementCache = [FBSession activeSessionCache];
        XCUIElement *element = [elementCache elementForUUID:specifiers[@"uuid"]];
        return handler(app, element, nil);
    } else if ([specifiers hasKey:@"coordinate"]) {
        CBXCoordinate *coord = [CBXCoordinate withJSON:specifiers[@"coordinate"]];
        return handler(app, nil, coord);
    } else {
        return noResultHandler();
    }
}

//Public facing version
//TODO: this is pretty dirty, refactor.
+ (BOOL)handleTouch:(NSDictionary *)specifiers options:(NSDictionary *)options {
    BOOL success;
    [[self new] handleTouch:specifiers options:options success:&success];
    return success;
}

- (id<FBResponsePayload>)handleTouch:(NSDictionary *)specifiers options:(NSDictionary *)options {
    return [self handleTouch:specifiers options:options success:nil];
}

- (id<FBResponsePayload>)handleTouch:(NSDictionary *)specifiers options:(NSDictionary *)options success:(BOOL *)success {
    if (success) {
        *success = NO;
    }
    
    //TODO: maybe remove this? Or always treat as touch and hold?
    double duration = 0.2;
    NSMutableDictionary *optCopy = [(options ?: @{}) mutableCopy];
    if ([options hasKey:@"duration"]) {
        duration = [options[@"duration"] doubleValue];
    }
    optCopy[@"duration"] = @(duration);
    
    if ([optCopy hasKey:@"duration"]) {
        return [self handleTouchAndHold:specifiers options:optCopy success:success];
    }
    
    //TODO: The below is supposed to be the default behavior, but does it work?
    
    if (![specifiers hasKey:@"coordinate"]) {
        //TODO: if users specifies a 'uuid', we could just use [element tap] ?
        
        return CBXResponseWithErrorFormat(@"Touch only supports coordinate. Please specify a 'coordinate' in the specifiers sub-object, e.g. { gesture: 'touch', specifiers : { coordinate : [ x, y ] }}");
    }
    CBXCoordinate *coord = [CBXCoordinate withJSON:specifiers[@"coordinate"]];
    CGFloat x = (CGFloat)coord.x;
    CGFloat y = (CGFloat)coord.y;
    
    if ([specifiers hasKey:@"uuid"]) {
        FBElementCache *elementCache = [FBSession activeSessionCache];
        XCUIElement *element = [elementCache elementForUUID:specifiers[@"uuid"]];
        if (element != nil) {
            CGRect rect = element.frame;
            x += rect.origin.x;
            y += rect.origin.y;
        }
    }
    [[CBXCommands tapCoordinateForX:x y:y] tap];

    if (success) {
        *success = YES;
    }
    return CBXResponseWithStatus(@"success", nil);
}

- (id<FBResponsePayload>)handleTouchAndHold:(NSDictionary *)specifiers options:(NSDictionary *)options {
    return [self handleTouch:specifiers options:options success:nil];
}

- (id<FBResponsePayload>)handleTouchAndHold:(NSDictionary *)specifiers options:(NSDictionary *)options success:(BOOL *)success {
    return [self getElementOrCoordinate:specifiers
                                handler:^(XCUIApplication *app,
                                          XCUIElement *element,
                                          CBXCoordinate *coord) {
        if (element) {
            [element pressForDuration:[options[@"duration"] doubleValue]];
        } else if (coord) {
            XCUICoordinate *xcCoord = [CBXGestureCommands tapCoordinateForX:coord.x
                                                                          y:coord.y];
            [xcCoord pressForDuration:[options[@"duration"] doubleValue]];
        }
        if (success) { *success = YES; }
        return CBXResponseWithStatus(@"success", nil);
    } noResultHandler:^id<FBResponsePayload>{
        if (success) { *success = NO; }
        return CBXResponseWithErrorFormat(@"No element found for specifiers: %@", specifiers.pretty);
    }];
}

- (id<FBResponsePayload>)handleEnterText:(NSDictionary *)specifiers options:(NSDictionary *)options {
    NSString *textToType = specifiers[@"string"];
    NSError *error;
    if (![FBKeyboard typeText:textToType error:&error]) {
        return CBXResponseWithError(error);
    }
    return CBXResponseWithStatus(@"success", nil);
}

- (id<FBResponsePayload>)handleClearText:(NSDictionary *)specifiers options:(NSDictionary *)options {
    NSString *elementUUID = specifiers[@"uuid"];
    XCUIElement *element;
    if (elementUUID) {
        FBElementCache *elementCache =  [FBSession activeSessionCache];
        element = [elementCache elementForUUID:elementUUID];
    } else {
        CBXTextInputFirstResponderProvider *provider = [CBXTextInputFirstResponderProvider new];
        element = [provider firstResponder];
    }
    if (element) {
        NSError *error;
        if (![element fb_clearTextWithError:&error]) {
            return FBResponseWithError(error);
        }
        return CBXResponseWithStatus(@"success", nil);
    } else {
        return CBXResponseWithErrorFormat(@"No element currently has typing focus!");
    }
}

- (id<FBResponsePayload>)handleDoubleTap:(NSDictionary *)specifiers options:(NSDictionary *)options {
    return [self getElementOrCoordinate:specifiers
                                handler:^id<FBResponsePayload>(XCUIApplication *app,
                                                               XCUIElement *element,
                                                               CBXCoordinate *coord) {
        if (element) {
            [element doubleTap];
        } else if (coord) {
            XCUICoordinate *xcCoord = [CBXGestureCommands tapCoordinateForX:coord.x
                                                                          y:coord.y];
            [xcCoord doubleTap];
        }
        return CBXResponseWithStatus(@"success", nil);
    } noResultHandler:^id<FBResponsePayload>{
        return CBXResponseWithErrorFormat(@"No element found for specifiers: %@", specifiers.pretty);
    }];
}

- (id<FBResponsePayload>)handleTwoFingerTap:(NSDictionary *)specifiers options:(NSDictionary *)options {
    return [self getElementOrCoordinate:specifiers
                                handler:^id<FBResponsePayload>(XCUIApplication *app,
                                                               XCUIElement *element,
                                                               CBXCoordinate *coord) {
        if (element) {
            [element twoFingerTap];
        } else {
            [app cbx_twoFingerTapAtCoordinate:coord.cgpoint withError:nil];
        }
        return CBXResponseWithStatus(@"success", nil);
    } noResultHandler:^id<FBResponsePayload>{
        return CBXResponseWithErrorFormat(@"No element found for specifiers: %@", specifiers.pretty);
    }];
}

- (id<FBResponsePayload>)handleDrag:(NSDictionary *)specifiers options:(NSDictionary *)options {
    if (![specifiers hasKey:@"coordinates"] || [specifiers[@"coordinates"] count] < 2) {
        return CBXResponseWithErrorFormat(@"Please specify two coordinates for drag. E.g. coordinates: [[fromX, fromY], [toX, toY]]");
    } else if ([specifiers[@"coordinates"] count] > 2) {
        [FBLogger log:@"Drag only supports 2 coordinates, the rest will be ignored."];
    }
    CGPoint fromPoint = [CBXCoordinate withJSON:specifiers[@"coordinates"][0]].cgpoint;
    CGPoint toPoint = [CBXCoordinate withJSON:specifiers[@"coordinates"][1]].cgpoint;

    
    CGVector startPoint = CGVectorMake(fromPoint.x, fromPoint.y);
    CGVector endPoint = CGVectorMake(toPoint.x, toPoint.y);
    
    //TODO: Good default value?
    NSTimeInterval duration = [options hasKey:@"duration"] ? [options[@"duration"] doubleValue] : 0.4;
    
    XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:[FBSession activeSession].application normalizedOffset:CGVectorMake(0, 0)];
    XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:endPoint];
    XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:startPoint];
    [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
    
    return CBXResponseWithStatus(@"success", nil);
}

- (id<FBResponsePayload>)handlePinch:(NSDictionary *)specifiers options:(NSDictionary *)options {
        //TODO: this is a sloppy conversion for quick and dirty backwards compat
        CGFloat scale;
        if ([options hasKey:@"amount"]) {
            scale = (CGFloat)[options[@"amount"] doubleValue];
            if ([options hasKey:@"pinch_direction"]) {
                if ([options[@"pinch_direction"] isEqualToString:@"in"]) {
                    scale = 1.0f / MAX(scale, 1.0f);
                }
            }
        } else if ([options hasKey:@"scale"]) {
            scale = (CGFloat)[options[@"scale"] doubleValue];
        } else {
            scale = 0.5f;
        }
        
        //TODO: sloppy for backwards compat
        CGFloat velocity;
        if ([options hasKey:@"duration"]) {
            velocity = (CGFloat)[options [@"duration"] doubleValue];
            if (scale < 1) {
                velocity *= -1.0f;
            }
        } else if ([options hasKey:@"velocity"]) {
            velocity = (CGFloat)[options [@"velocity"] doubleValue];
        } else {
            velocity =  scale < 1 ? -1.0f : 1.0f;
        }
        [FBLogger logFmt:@"pinchWithScale:%f velocity:%f", scale, velocity];
    return [self getElementOrCoordinate:specifiers
                                handler:^id<FBResponsePayload>(XCUIApplication *app,
                                                               XCUIElement *element,
                                                               CBXCoordinate *coord) {
        if (element) {
            [element pinchWithScale:scale velocity:velocity];
        } else {
            [app cbx_pinchAtCoordinate:coord.cgpoint
                                 scale:scale
                              velocity:velocity
                             withError:nil];
        }
        return CBXResponseWithStatus(@"success", @{
                                                   @"scale" : @(scale),
                                                   @"velocity" : @(velocity)
                                                   });
    } noResultHandler:^id<FBResponsePayload>{
        return CBXResponseWithErrorFormat(@"No element found for specifiers: %@", specifiers.pretty);
    }];
}

- (id<FBResponsePayload>)handleRotate:(NSDictionary *)specifiers options:(NSDictionary *)options {
    return CBXResponseWithErrorFormat(@"Finger rotation is not not implemented...");
}

+ (id<FBResponsePayload>)handleGesture:(FBRouteRequest *)request {
    NSString *gesture = request.arguments[@"gesture"];
    NSString *handlerName = gestureMap[gesture];
    if (!handlerName) {
        return CBXResponseWithErrorFormat(@"Unsupported gesture: %@", gesture);
    }
    NSDictionary *specifiers = request.arguments[@"specifiers"];
    NSDictionary *options = request.arguments[@"options"];
    SEL handler = NSSelectorFromString(handlerName);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    CBXGestureCommands *performer = self.new;
    if ([performer respondsToSelector:handler]) {
        return [self.new performSelector:handler withObject:specifiers withObject:options];
    } else {
        return CBXResponseWithException([NSException exceptionWithName:@"ProgrammerErrorException"
                                                                reason:@"Un-implemented selector"
                                                              userInfo:@{@"selector" : handlerName}]);
    }
#pragma clang diagnostic pop
}

@end
