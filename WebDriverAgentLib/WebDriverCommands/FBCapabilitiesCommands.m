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
#import "FBWDAConstants.h"
#import "UIAApplication.h"
#import "UIATarget.h"

extern BOOL AXDeviceIsPad();

@implementation FBCapabilitiesCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/session/:sessionID"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class currentCapabilities]);
    }],
    [[FBRoute GET:@"/status"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{
          @"state" : @"success",
          @"os" : @{
            @"name" : [[UIATarget localTarget] systemName],
            @"version" : [NSString stringWithFormat:@"%@ (%@)",
              [[UIATarget localTarget] systemVersion],
              [[UIATarget localTarget] systemBuild]
            ],
          },
          @"ios" : @{
            @"simulatorVersion" : [[UIATarget localTarget] systemVersion],
          },
          @"supportedApps" : [self.class supportedApps],
          @"build" : @{
            @"time" : [self.class buildTimestamp],
          },
          @"currentApp": [self applicationDetailsForApplication:UIATarget.localTarget.frontMostApp]
        }
      );
    }],
    [[FBRoute POST:@"/session/:sessionID/deactivateApp"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      id duration = request.arguments[@"duration"];
      // TODO(t8051359): This is terrible and we should file a Radar for this.
      if (FBWDAConstants.isIOS9OrGreater) {
        [UIATarget.localTarget lockForDuration:duration];
      } else {
        duration ? [UIATarget.localTarget deactivateAppForDuration:duration] : [UIATarget.localTarget deactivateApp];
      }
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute DELETE:@"session/:sessionID"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSLog(@"Just issued command to quit!");
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/timeouts/implicit_wait"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      // This method is intentionally not supported.
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/location"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [[UIATarget localTarget] setLocation:@{ @"latitude": request.arguments[@"latitude"], @"longitude": request.arguments[@"longitude"] }];
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

+ (NSArray *)supportedApps
{
  NSMutableArray *array = [NSMutableArray array];
  for (UIAApplication *app in [[UIATarget localTarget] applications]) {
    [array addObject:[self applicationDetailsForApplication:app]];
  }
  return array.copy;
}

+ (NSDictionary *)currentCapabilities
{
  return @{
    @"CFBundleIdentifier": [[[UIATarget localTarget] frontMostApp] bundleID] ?: NSNull.null,
    @"CFBundleVersion": [[[UIATarget localTarget] frontMostApp] bundleVersion] ?: NSNull.null,
    @"device": AXDeviceIsPad() ? @"ipad" : @"iphone",
    @"sdkVersion": [[UIATarget localTarget] systemVersion] ?: NSNull.null,
    @"browserName": [[[UIATarget localTarget] frontMostApp] name] ?: NSNull.null,
  };
}

+ (NSDictionary *)applicationDetailsForApplication:(UIAApplication *)application
{
  return @{
    @"name" : [application name] ?: NSNull.null,
    @"version" : [application version] ?: NSNull.null,
    @"bundleVersion" : [application bundleVersion] ?: NSNull.null,
    @"bundleID" : [application bundleID] ?: NSNull.null,
    @"bundlePath" : [application bundlePath] ?: NSNull.null,
    @"stateDescription" : [application stateDescription] ?: NSNull.null,
  };
}

@end
