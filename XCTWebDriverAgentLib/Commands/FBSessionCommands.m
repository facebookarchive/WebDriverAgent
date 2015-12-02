/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSessionCommands.h"

#import "FBRouteRequest.h"
#import "FBXCTSession.h"

#import "XCUIApplication.h"
#import "XCUIDevice.h"

@implementation FBSessionCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/session"].withoutSession respond:^ id<FBResponsePayload> (FBRouteRequest *request) {

      NSDictionary *requirements = request.arguments[@"desiredCapabilities"];
        NSString *bundleID = requirements[@"bundleId"];
        NSString *appPath = requirements[@"app"];
        NSAssert(bundleID, @"'bundleId' desired capability not provided");
        NSAssert(appPath, @"'app' desired capability not provided");

      XCUIApplication *app = [[XCUIApplication alloc] initPrivateWithPath:appPath bundleID:bundleID];
      app.launchArguments = requirements[@"arguments"] ?: @[];
      app.launchEnvironment = requirements[@"environment"] ?: @{};
      [app launch];
      [FBXCTSession sessionWithXCUIApplication:app];
      return [FBResponsePayload okWith:
       @{
         @"capabilities" : [self.class currentCapabilities],
        }
       ];
    }],
    [[FBRoute GET:@""] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class currentCapabilities]);
    }],
    [[FBRoute GET:@"/status"].withoutSession respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{
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
        }
      );
    }],
    [[FBRoute DELETE:@""] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      [request.session kill];
      return FBResponseDictionaryWithOK();
    }],
  ];
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
