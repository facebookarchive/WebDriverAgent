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
#import "FBConfiguration.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "XCUIDevice.h"
#import "XCUIDevice+FBHealthCheck.h"
#import "XCUIDevice+FBHelpers.h"

@implementation FBSessionCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/url"] respondWithTarget:self action:@selector(handleOpenURL:)],
    [[FBRoute POST:@"/session"].withoutSession respondWithTarget:self action:@selector(handleCreateSession:)],
    [[FBRoute GET:@""] respondWithTarget:self action:@selector(handleGetActiveSession:)],
    [[FBRoute DELETE:@""] respondWithTarget:self action:@selector(handleDeleteSession:)],
    [[FBRoute GET:@"/status"].withoutSession respondWithTarget:self action:@selector(handleGetStatus:)],

    // Health check might modify simulator state so it should only be called in-between testing sessions
    [[FBRoute GET:@"/wda/healthcheck"].withoutSession respondWithTarget:self action:@selector(handleGetHealthCheck:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleOpenURL:(FBRouteRequest *)request
{
  NSString *urlString = request.arguments[@"url"];
  if (!urlString) {
    return FBResponseWithStatus(FBCommandStatusInvalidArgument, @"URL is required");
  }
  NSURL *url = [NSURL URLWithString:urlString];
  if (!url) {
    return FBResponseWithStatus(
      FBCommandStatusInvalidArgument,
      [NSString stringWithFormat:@"%@ is not a valid URL", url]
    );
  }
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  if (![[UIApplication sharedApplication] openURL:url]) {
    return FBResponseWithErrorFormat(@"Failed to open %@", url);
  }
  #pragma clang diagnostic pop
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleCreateSession:(FBRouteRequest *)request
{
  NSDictionary *requirements = request.arguments[@"desiredCapabilities"];
  NSString *bundleID = requirements[@"bundleId"];
  NSString *appPath = requirements[@"app"];
  if (!bundleID) {
    return FBResponseWithErrorFormat(@"'bundleId' desired capability not provided");
  }
  [FBConfiguration setShouldUseTestManagerForVisibilityDetection:[requirements[@"shouldUseTestManagerForVisibilityDetection"] boolValue]];
  if (requirements[@"maxTypingFrequency"]) {
    [FBConfiguration setMaxTypingFrequency:[requirements[@"maxTypingFrequency"] integerValue]];
  }
  if (requirements[@"shouldUseSingletonTestManager"]) {
    [FBConfiguration setShouldUseSingletonTestManager:[requirements[@"shouldUseSingletonTestManager"] boolValue]];
  }

  FBApplication *app = [[FBApplication alloc] initPrivateWithPath:appPath bundleID:bundleID];
  app.fb_shouldWaitForQuiescence = [requirements[@"shouldWaitForQuiescence"] boolValue];
  app.launchArguments = (NSArray<NSString *> *)requirements[@"arguments"] ?: @[];
  app.launchEnvironment = (NSDictionary <NSString *, NSString *> *)requirements[@"environment"] ?: @{};
  [app launch];

  if (app.processID == 0) {
    return FBResponseWithErrorFormat(@"Failed to launch %@ application", bundleID);
  }
  [FBSession sessionWithApplication:app];
  return FBResponseWithObject(FBSessionCommands.sessionInformation);
}

+ (id<FBResponsePayload>)handleGetActiveSession:(FBRouteRequest *)request
{
  return FBResponseWithObject(FBSessionCommands.sessionInformation);
}

+ (id<FBResponsePayload>)handleDeleteSession:(FBRouteRequest *)request
{
  [request.session kill];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetStatus:(FBRouteRequest *)request
{
  return
  FBResponseWithStatus(
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
          @"ip" : [XCUIDevice sharedDevice].fb_wifiIPAddress ?: [NSNull null],
        },
      @"build" :
        @{
          @"time" : [self.class buildTimestamp],
        },
    }
  );
}

+ (id<FBResponsePayload>)handleGetHealthCheck:(FBRouteRequest *)request
{
  if (![[XCUIDevice sharedDevice] fb_healthCheckWithApplication:[FBApplication fb_activeApplication]]) {
    return FBResponseWithErrorFormat(@"Health check failed");
  }
  return FBResponseWithOK();
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
  };
}

@end
