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
#import "FBWDAMacros.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+WebDriverAttributes.h"

@implementation FBDebugCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/source"] respondWithTarget:self action:@selector(handleGetTreeCommand:)],
    [[FBRoute GET:@"/source"].withoutSession respondWithTarget:self action:@selector(handleGetTreeCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetTreeCommand:(FBRouteRequest *)request
{
  return [self handleGetTree:request accessible:[request.arguments[@"accessible"] boolValue]];
}

#pragma mark - Helpers

+ (id<FBResponsePayload>)handleGetTree:(FBRouteRequest *)request accessible:(BOOL)accessible
{
  FBApplication *application = request.session.application ?: [FBApplication fb_activeApplication];
  if (!application) {
    return FBResponseWithErrorFormat(@"There is no active application");
  }

  NSDictionary *info = accessible ? [self accessibilityInfoForElement:application.lastSnapshot] : [self infoForElement:application.lastSnapshot];
  return FBResponseWithStatus(FBCommandStatusNoError, @{ @"tree": info });
}

+ (NSDictionary *)infoForElement:(XCElementSnapshot *)snapshot
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
  info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
  info[@"name"] = FBValueOrNull(snapshot.wdName);
  info[@"value"] = FBValueOrNull(snapshot.wdValue);
  info[@"label"] = FBValueOrNull(snapshot.wdLabel);
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

+ (NSDictionary *)accessibilityInfoForElement:(XCElementSnapshot *)snapshot
{
  BOOL isAccessible = [snapshot isWDAccessible];

  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

  if (isAccessible) {
    info[@"value"] = FBValueOrNull(snapshot.wdValue);
    info[@"label"] = FBValueOrNull(snapshot.wdLabel);
  } else {
    NSArray *childElements = snapshot.children;
    if ([childElements count]) {
      info[@"children"] = [[NSMutableArray alloc] init];
      for (XCElementSnapshot *childSnapshot in childElements) {
        NSDictionary *childInfo = [self infoForElement:childSnapshot];
        if ([childInfo count]) {
          [info[@"children"] addObject: childInfo];
        }
      }
    }
  }
  if ([info count]) {
    info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
    info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
    info[@"name"] = FBValueOrNull(snapshot.wdName);
  }
  return info;
}

@end
