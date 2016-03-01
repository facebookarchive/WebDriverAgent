/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBCustomCommands.h"

#import <XCTest/XCUIDevice.h>

#import "FBResponsePayload.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBXCTSession.h"
#import "XCUIApplication+SpringBoard.h"

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/deactivateApp"] respondWithTarget:self action:@selector(handleDeactivateAppCommand:)],
    [[FBRoute GET:@"/timeouts/implicit_wait"] respondWithTarget:self action:@selector(handleImplicitWaitCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleDeactivateAppCommand:(FBRouteRequest *)request
{
  NSString *applicationIdentifier = ((FBXCTSession *)request.session).application.label;

  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];

  NSNumber *requestedDuration = request.arguments[@"duration"];
  CGFloat duration = (requestedDuration ? requestedDuration.floatValue : 3.f);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];

  [[XCUIApplication fb_SpringBoard] fb_tapApplicationWithIdentifier:applicationIdentifier];
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleImplicitWaitCommand:(FBRouteRequest *)request
{
  // This method is intentionally not supported.
  return FBResponseDictionaryWithOK();
}

@end
