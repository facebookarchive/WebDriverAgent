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

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"GET@/session/:sessionID" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class currentCapabilities]));
    },
    @"GET@/status" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{
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
      ));
    },
    @"POST@/session/:sessionID/deactivateApp" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      id duration = request.arguments[@"duration"];
      // TODO(t8051359): This is terrible and we should file a Radar for this.
      if (FBWDAConstants.isIOS9OrGreater) {
        [UIATarget.localTarget lockForDuration:duration];
      } else {
        duration ? [UIATarget.localTarget deactivateAppForDuration:duration] : [UIATarget.localTarget deactivateApp];
      }
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"DELETE@/session/:sessionID" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSLog(@"Just issued command to quit!");
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/timeouts/implicit_wait" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      // This method is intentionally not supported.
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/location" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [[UIATarget localTarget] setLocation:@{ @"latitude": request.arguments[@"latitude"], @"longitude": request.arguments[@"longitude"] }];
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
