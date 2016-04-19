/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSessionCommands.h"

#import "FBApplication.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "XCUIDevice.h"

@implementation FBSessionCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/session"].withoutSession respondWithTarget:self action:@selector(handleCreateSession:)],
    [[FBRoute GET:@""] respondWithTarget:self action:@selector(handleGetActiveSession:)],
    [[FBRoute DELETE:@""] respondWithTarget:self action:@selector(handleDeleteSession:)],
    [[FBRoute GET:@"/status"].withoutSession respondWithTarget:self action:@selector(handleGetStatus:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleCreateSession:(FBRouteRequest *)request
{
  NSDictionary *requirements = request.arguments[@"desiredCapabilities"];
  NSString *bundleID = requirements[@"bundleId"];
  NSString *appPath = requirements[@"app"];
  NSAssert(bundleID, @"'bundleId' desired capability not provided");
  FBApplication *app = [[FBApplication alloc] initPrivateWithPath:appPath bundleID:bundleID];
  app.shouldWaitForQuiescence = [requirements[@"shouldWaitForQuiescence"] boolValue];
  app.launchArguments = (NSArray<NSString *> *)requirements[@"arguments"] ?: @[];
  app.launchEnvironment = (NSDictionary <NSString *, NSString *> *)requirements[@"environment"] ?: @{};
  [app launch];
  [FBSession sessionWithApplication:app];
  return [FBResponsePayload okWith:FBSessionCommands.sessionInformation];
}

+ (id<FBResponsePayload>)handleGetActiveSession:(FBRouteRequest *)request
{
  return [FBResponsePayload okWith:FBSessionCommands.sessionInformation];
}

+ (id<FBResponsePayload>)handleGetStatus:(FBRouteRequest *)request
{
  return
  FBResponseDictionaryWithStatus(
    FBCommandStatusNoError,
    @{
      @"state" : @"success",
      @"os" :
        @{
          @"name" : [[UIDevice currentDevice] systemName],
          @"version" : [[UIDevice currentDevice] systemVersion],
        },
      @"ios" :
        @{
          @"simulatorVersion" : [[UIDevice currentDevice] systemVersion],
        },
      @"build" :
        @{
          @"time" : [self.class buildTimestamp],
        },
    }
  );
}

+ (id<FBResponsePayload>)handleDeleteSession:(FBRouteRequest *)request
{
  [request.session kill];
  return FBResponseDictionaryWithOK();
}


#pragma mark - Helpers

+ (NSString *)buildTimestamp
{
  return [NSString stringWithFormat:@"%@ %@",
    [NSString stringWithUTF8String:__DATE__],
    [NSString stringWithUTF8String:__TIME__]
  ];
}

+ (NSDictionary *)sessionInformation
{
  return
  @{
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"capabilities" : FBSessionCommands.currentCapabilities
  };
}

+ (NSDictionary *)currentCapabilities
{
  FBApplication *application = [FBSession activeSession].application;
  return
  @{
    @"device": ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @"ipad" : @"iphone",
    @"sdkVersion": [[UIDevice currentDevice] systemVersion],
    @"browserName": application.label ?: [NSNull null],
    @"CFBundleIdentifier": application.bundleID ?: [NSNull null],
    @"applicationProcessID": @(application.processID),
    @"webdriverProcessID": @([NSProcessInfo processInfo].processIdentifier),
  };
}

@end
