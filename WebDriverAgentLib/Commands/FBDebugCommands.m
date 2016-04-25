/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBDebugCommands.h"

#import "FBApplication.h"
#import "FBElementTypeTransformer.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCAccessibilityElement.h"
#import "XCAXClient_iOS.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

static id ValueOrNull(id value) {
  return value ?: [NSNull null];
}

@implementation FBDebugCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/tree"].withoutSession respondWithTarget:self action:@selector(handleGetActiveTreeCommand:)],
    [[FBRoute GET:@"/tree"] respondWithTarget:self action:@selector(handleGetTreeCommand:)],
    [[FBRoute GET:@"/source"] respondWithTarget:self action:@selector(handleGetTreeCommand:)],
    [[FBRoute GET:@"/source"].withoutSession respondWithTarget:self action:@selector(handleGetActiveTreeCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetActiveTreeCommand:(FBRouteRequest *)request
{
  FBApplication *application = [self activeApplication];
  if (!application) {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @"There is no active application");
  }
  return [self handleTreeCommandWithParams:application];
}

+ (FBApplication *)activeApplication
{
  XCAccessibilityElement *activeApplicationElement = [[[XCAXClient_iOS sharedClient] activeApplications] firstObject];
  if (!activeApplicationElement) {
      return nil;
  }
  FBApplication *application = [FBApplication appWithPID:activeApplicationElement.processIdentifier];
  [application query];
  [application resolve];
  return application;
}

+ (id<FBResponsePayload>)handleGetTreeCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  return [self handleTreeCommandWithParams:session.application];
}


#pragma mark - Helpers

+ (id<FBResponsePayload>)handleTreeCommandWithParams:(FBApplication *)application
{
  NSDictionary *info = [self.class JSONTreeForTargetForApplication:application];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{ @"tree": info });
}

+ (NSDictionary *)JSONTreeForTargetForApplication:(FBApplication *)app
{
  NSDictionary *info = [self infoForElement:app.lastSnapshot];
  return info;
}

+ (NSDictionary *)infoForElement:(XCElementSnapshot *)snapshot
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
  info[@"rawIdentifier"] = ValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
  info[@"name"] = ValueOrNull(snapshot.wdName);
  info[@"value"] = ValueOrNull(snapshot.wdValue);
  info[@"label"] = ValueOrNull(snapshot.wdLabel);
  info[@"rect"] = snapshot.wdRect;
  info[@"frame"] = NSStringFromCGRect(snapshot.wdFrame);
  info[@"isEnabled"] = [@([snapshot isWDEnabled]) stringValue];
  info[@"isVisible"] = [@([snapshot isWDVisible]) stringValue];

  NSArray *childElements = snapshot.children;
  if ([childElements count]) {
    info[@"children"] = [[NSMutableArray alloc] init];
    for (XCElementSnapshot *childSnapshot in childElements) {
      [info[@"children"] addObject:[self infoForElement:childSnapshot]];
    }
  }
  return info;
}

@end
