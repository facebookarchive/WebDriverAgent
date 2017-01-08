
#import "CBXDeviceEventCommands.h"
#import "FBRunLoopSpinner.h"
#import "XCDeviceEvent.h"
#import "XCTestDriver.h"
#import <XCTest/XCUIDevice.h>
#import "FBLogger.h"

/**
    For an opaque explanation of device event codes, stare at this page:
    http://iphonedevwiki.net/index.php/IOHIDFamily
 */
#define HOME_BUTTON_PAGE 0x0C //not entirely accurate description
#define PRESS 0x40 //not entirely accurate description either, but I don't have a better one

@implementation CBXDeviceEventCommands

+ (NSArray *)routes {
    return @[
             [[FBRoute POST:CBXRoute(@"/home")].withoutSession respondWithTarget:self
                                                                          action:@selector(handleHome:)],
             [[FBRoute POST:CBXRoute(@"/siri")].withoutSession respondWithTarget:self
                                                                          action:@selector(handleSiri:)],
             [[FBRoute POST:CBXRoute(@"/volume")].withoutSession respondWithTarget:self
                                                                           action:@selector(handleVolume:)],
             [[FBRoute POST:CBXRoute(@"/rotate_home_button_to")].withCBXSession respondWithTarget:self
                                                                            action:@selector(handleRotateHomeButtonTo:)]
             ];
}

+ (id<FBResponsePayload>)pressHomeButtonForDuration:(int)duration {
    int page = HOME_BUTTON_PAGE;
    int usage = PRESS;
    
    id event = [NSClassFromString(@"XCDeviceEvent") deviceEventWithPage:page usage:usage duration:duration];
    
    __block NSError *outer = nil;
    [FBRunLoopSpinner spinUntilCompletion:^(void (^ _Nonnull completion)()) {
        [[XCTestDriver sharedTestDriver].managerProxy _XCT_performDeviceEvent:event completion:^(NSError *e) {
            if (e) {
                outer = e;
                [FBLogger logFmt:@"Error pressing home button for duration %d: %@", duration, e];
            }
            completion();
        }];
    }];
    if (outer) {
        return CBXResponseWithError(outer);
    }
    return CBXResponseWithStatus(@"Ok", nil);
}

+ (id<FBResponsePayload>)handleHome:(FBRouteRequest *)request {
    return [self pressHomeButtonForDuration:1];
}

+ (id<FBResponsePayload>)handleSiri:(FBRouteRequest *)request {
    return [self pressHomeButtonForDuration:5];
}

+ (id<FBResponsePayload>)handleVolume:(FBRouteRequest *)request {
     NSString *volumeDirection = [request.arguments[@"volume"] lowercaseString];
     int page = 0xC; //12
     int direction;
     if ([volumeDirection isEqualToString:@"up"]) {
         direction = 0xE9;
     } else if ([volumeDirection isEqualToString:@"down"]) {
         direction = 0XEA;
     } else {
         return CBXResponseWithException([NSException exceptionWithName:@"InvalidArgumentException"
                                        reason:@"Invalid volume direction. Please specify 'up' or 'down'"
                                      userInfo:@{@"direction" : volumeDirection ?: @""}]);
     }
     
     id event = [NSClassFromString(@"XCDeviceEvent") deviceEventWithPage:page
                                                                   usage:direction
                                                                duration:0.2];
    __block NSError *outer;
    [FBRunLoopSpinner spinUntilCompletion:^(void (^ _Nonnull completion)()) {
        [[XCTestDriver sharedTestDriver].managerProxy _XCT_performDeviceEvent:event completion:^(NSError *e) {
            if (e) {
                outer = e;
                [FBLogger logFmt:@"Error adjusting volume: %@", e];
            }
            completion();
        }];
    }];
    if (outer) {
        return CBXResponseWithError(outer);
    } else {
        return CBXResponseWithJSON(@{@"status" : @"success", @"volumeDirection" : volumeDirection});
    }
}

+ (id<FBResponsePayload>)handleRotateHomeButtonTo:(FBRouteRequest *)request {
    [XCUIDevice sharedDevice].orientation = (UIDeviceOrientation)[request.arguments[@"orientation"] longLongValue];
    return CBXResponseWithJSON(@{
                                 @"status" : @"success",
                                 @"orientation" : @([XCUIDevice sharedDevice].orientation)
                                 });
}
@end
