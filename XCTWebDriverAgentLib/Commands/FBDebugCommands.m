/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBDebugCommands.h"

#import "FBRouteRequest.h"
#import "FBXCTSession.h"

#import "XCUIApplication.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+UIAClassMapping.h"
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
    [[FBRoute GET:@"/tree"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return [self handleTreeCommandWithParams:request];
    }],
    [[FBRoute GET:@"/session/:sessionID/tree"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return [self handleTreeCommandWithParams:request];
    }],
    [[FBRoute GET:@"/session/:sessionID/source"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return [self handleTreeCommandWithParams:request];
    }],
  ];
}

#pragma mark - Helpers

+ (id<FBResponsePayload>)handleTreeCommandWithParams:(FBRouteRequest *)request
{
  FBXCTSession *session = (FBXCTSession *)request.session;
  NSDictionary *info = [self.class JSONTreeForTargetForApplication:session.application];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{ @"tree": info });
}

+ (NSDictionary *)JSONTreeForTargetForApplication:(XCUIApplication *)app
{
  NSDictionary *info = [self infoForElement:app.lastSnapshot];
  return info;
}

+ (NSDictionary *)infoForElement:(XCElementSnapshot *)snapshot
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  info[@"type"] = [XCUIElement UIAClassNameWithElementType:snapshot.elementType];
  info[@"name"] = ValueOrNull(snapshot.wdName);
  info[@"value"] = ValueOrNull(snapshot.wdValue);
  info[@"label"] = ValueOrNull(snapshot.wdLabel);
  info[@"rect"] = NSStringFromCGRect(snapshot.wdFrame);
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
