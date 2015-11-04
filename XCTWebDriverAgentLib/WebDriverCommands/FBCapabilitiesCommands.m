/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBCapabilitiesCommands.h"

#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIApplication.h"
#import "XCUIDevice.h"

@implementation FBCapabilitiesCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"POST@/session" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {

      NSDictionary *requirements = request.arguments[@"desiredCapabilities"];
      NSString *bundleID = requirements[@"app"];
      NSString *appPath = requirements[@"bundleId"];
      NSAssert(bundleID != nil, @"Should have bundle ID");
      NSAssert(appPath != nil, @"Should have app path");
      
      XCUIApplication *app = [[XCUIApplication alloc] initPrivateWithPath:appPath bundleID:bundleID];
      app.launchArguments = requirements[@"arguments"] ?: @[];
      [app launch];
      FBSession *session = [FBSession sessionWithXCUIApplication:app];
      completionHandler(
                        @{
                          @"sessionId" : session.identifier,
                          @"value" : [self.class currentCapabilities],
                          @"status" : @(FBCommandStatusNoError),
                          });
    },
    @"GET@/session/:sessionID" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class currentCapabilities]));
    },
    @"GET@/status" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{
          @"state" : @"success",
          @"os" : @{
            @"name" : [[UIDevice currentDevice] systemName],
            @"version" : [[UIDevice currentDevice] systemVersion],
          },
          @"ios" : @{
            @"simulatorVersion" : [[UIDevice currentDevice] systemVersion],
          },
          @"build" : @{
            @"time" : [self.class buildTimestamp],
          },
          @"sessions" : [[FBSession activeSessions] valueForKeyPath:@"@unionOfObjects.description"]
        }
      ));
    },
    @"POST@/session/:sessionID/deactivateApp" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"DELETE@/session/:sessionID" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [request.session.application terminate];
      [request.session kill];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/timeouts/implicit_wait" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      // This method is intentionally not supported.
      completionHandler(FBResponseDictionaryWithOK());
    },
  };
}

#pragma mark - Helpers

+ (NSString *)buildTimestamp
{
  return [NSString stringWithFormat:@"%@ %@",
    [NSString stringWithUTF8String:__DATE__],
    [NSString stringWithUTF8String:__TIME__]
  ];
}

+ (NSDictionary *)currentCapabilities
{
  return @{
    @"device": ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @"ipad" : @"iphone",
    @"sdkVersion": [[UIDevice currentDevice] systemVersion],
    @"browserName": [[UIDevice currentDevice] name],
  };
}

@end
