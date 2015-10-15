/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSessionCommands.h"

#import "FBRequest.h"

#import "UIAApplication.h"
#import "UIATarget.h"

extern BOOL AXDeviceIsPad();

static NSString *currentSessionID;

@implementation FBSessionCommands

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/status"].sessionNotRequired respond: ^ id<FBResponse> (FBRequest *request) {
      return [FBResponse okWith:FBSessionCommands.statusDictionary];
    }],
    [[FBRoute POST:@"/session"].sessionNotRequired respond:^ id<FBResponse> (FBRequest *request) {
      if (FBSessionCommands.sessionId) {
        return [FBResponse withStatus:FBCommandStatusNoSuchSession object:currentSessionID];
      }

      currentSessionID = NSUUID.UUID.UUIDString;
      return [FBResponse okWith:FBSessionCommands.sessionInformation];
    }],
    [[FBRoute GET:@"/sessions"].sessionNotRequired respond:^ id<FBResponse> (FBRequest *request) {
      return [FBResponse okWith:@[FBSessionCommands.sessionInformation]];
    }],
    [[FBRoute GET:@""] respond: ^ id<FBResponse> (FBRequest *request) {
      return [FBResponse okWith:FBSessionCommands.currentCapabilities];
    }],
    [[FBRoute DELETE:@""] respond:^ id<FBResponse> (FBRequest *request) {
      currentSessionID = nil;
      return FBResponse.ok;
    }]
  ];
}

+ (NSString *)sessionId
{
  return currentSessionID;
}

#pragma mark Helpers

+ (NSDictionary *)statusDictionary
{
  return @{
    @"state" : @"success",
    @"os" : @{
      @"name" : [UIATarget.localTarget systemName],
      @"version" : [self versionString],
    },
    @"ios" : @{
      @"simulatorVersion" : [UIATarget.localTarget systemVersion],
    },
    @"supportedApps" : [self supportedApps],
    @"build" : @{
      @"time" : [self buildTimestamp],
    },
    @"currentApp": [self applicationDetailsForApplication:UIATarget.localTarget.frontMostApp]
  };
}

+ (NSString *)versionString
{
  return [NSString stringWithFormat:
    @"%@ (%@)",
    [UIATarget.localTarget systemVersion],
    [UIATarget.localTarget systemBuild]
  ];
}

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

+ (NSDictionary *)sessionInformation
{
  return @{
    @"sessionId" : FBSessionCommands.sessionId ?: NSNull.null,
    @"capabilities" : FBSessionCommands.currentCapabilities
  };
}

+ (NSDictionary *)currentCapabilities
{
  return @{
    @"CFBundleIdentifier": [[UIATarget.localTarget frontMostApp] bundleID] ?: NSNull.null,
    @"CFBundleVersion": [[UIATarget.localTarget frontMostApp] bundleVersion] ?: NSNull.null,
    @"device": AXDeviceIsPad() ? @"ipad" : @"iphone",
    @"sdkVersion": [UIATarget.localTarget systemVersion] ?: NSNull.null,
    @"browserName": [[UIATarget.localTarget frontMostApp] name] ?: NSNull.null,
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
