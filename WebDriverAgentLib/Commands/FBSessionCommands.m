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
#import "FBRuntimeUtils.h"
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
    [[FBRoute POST:@"/wda/apps/launch"] respondWithTarget:self action:@selector(handleSessionAppLaunch:)],
    [[FBRoute POST:@"/wda/apps/activate"] respondWithTarget:self action:@selector(handleSessionAppActivate:)],
    [[FBRoute POST:@"/wda/apps/terminate"] respondWithTarget:self action:@selector(handleSessionAppTerminate:)],
    [[FBRoute POST:@"/wda/apps/state"] respondWithTarget:self action:@selector(handleSessionAppState:)],
    [[FBRoute GET:@""] respondWithTarget:self action:@selector(handleGetActiveSession:)],
    [[FBRoute DELETE:@""] respondWithTarget:self action:@selector(handleDeleteSession:)],
    [[FBRoute GET:@"/status"].withoutSession respondWithTarget:self action:@selector(handleGetStatus:)],

    // Health check might modify simulator state so it should only be called in-between testing sessions
    [[FBRoute GET:@"/wda/healthcheck"].withoutSession respondWithTarget:self action:@selector(handleGetHealthCheck:)],
    
    // Settings endpoints
    [[FBRoute GET:@"/appium/settings"] respondWithTarget:self action:@selector(handleGetSettings:)],
    [[FBRoute POST:@"/appium/settings"] respondWithTarget:self action:@selector(handleSetSettings:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleOpenURL:(FBRouteRequest *)request
{
  NSString *urlString = request.arguments[@"url"];
  if (!urlString) {
    return FBResponseWithStatus(FBCommandStatusInvalidArgument, @"URL is required");
  }
  NSError *error;
  if (![XCUIDevice.sharedDevice fb_openUrl:urlString error:&error]) {
    return FBResponseWithError(error);
  }
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
  if (requirements[@"shouldUseCompactResponses"]) {
    [FBConfiguration setShouldUseCompactResponses:[requirements[@"shouldUseCompactResponses"] boolValue]];
  }
  NSString *elementResponseAttributes = requirements[@"elementResponseAttributes"];
  if (elementResponseAttributes) {
    [FBConfiguration setElementResponseAttributes:elementResponseAttributes];
  }
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

+ (id<FBResponsePayload>)handleSessionAppLaunch:(FBRouteRequest *)request
{
  [request.session launchApplicationWithBundleId:(id)request.arguments[@"bundleId"]
                                       arguments:request.arguments[@"arguments"]
                                     environment:request.arguments[@"environment"]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSessionAppActivate:(FBRouteRequest *)request
{
  [request.session activateApplicationWithBundleId:(id)request.arguments[@"bundleId"]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSessionAppTerminate:(FBRouteRequest *)request
{
  BOOL result = [request.session terminateApplicationWithBundleId:(id)request.arguments[@"bundleId"]];
  return FBResponseWithStatus(FBCommandStatusNoError, @(result));
}

+ (id<FBResponsePayload>)handleSessionAppState:(FBRouteRequest *)request
{
  NSUInteger state = [request.session applicationStateWithBundleId:(id)request.arguments[@"bundleId"]];
  return FBResponseWithStatus(FBCommandStatusNoError, @(state));
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
          @"sdkVersion": FBSDKVersion() ?: @"unknown",
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

+ (id<FBResponsePayload>)handleGetSettings:(FBRouteRequest *)request
{
  return FBResponseWithObject(
    @{
      @"shouldUseCompactResponses": @([FBConfiguration shouldUseCompactResponses]),
      @"elementResponseAttributes": [FBConfiguration elementResponseAttributes]
    }
  );
}

// TODO if we get lots more settings, handling them with a series of if-statements will be unwieldy
// and this should be refactored
+ (id<FBResponsePayload>)handleSetSettings:(FBRouteRequest *)request
{
  NSDictionary* settings = request.arguments[@"settings"];
  
  if ([settings objectForKey:@"shouldUseCompactResponses"]) {
    BOOL shouldUseCompactResponses = [[settings objectForKey:@"shouldUseCompactResponses"] boolValue];
    [FBConfiguration setShouldUseCompactResponses:shouldUseCompactResponses];
  }
  
  if ([settings objectForKey:@"elementResponseAttributes"]) {
    NSString* elementResponseAttribute = [settings objectForKey:@"elementResponseAttributes"];
    [FBConfiguration setElementResponseAttributes:elementResponseAttribute];
  }
  
  return [self handleGetSettings:request];
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
  FBApplication *application = [FBSession activeSession].activeApplication;
  return
  @{
    @"device": ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @"ipad" : @"iphone",
    @"sdkVersion": [[UIDevice currentDevice] systemVersion],
    @"browserName": application.label ?: [NSNull null],
    @"CFBundleIdentifier": application.bundleID ?: [NSNull null],
  };
}

@end
