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
    [[FBRoute POST:@"/deactivateApp"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSString *applicationIdentifier = ((FBXCTSession *)request.session).application.label;

      [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];

      NSNumber *requestedDuration = request.arguments[@"duration"];
      CGFloat duration = (requestedDuration ? requestedDuration.floatValue : 3.f);
      [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];

      [[XCUIApplication fb_SpringBoard] fb_tapApplicationWithIdentifier:applicationIdentifier];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/timeouts/implicit_wait"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      // This method is intentionally not supported.
      return FBResponseDictionaryWithOK();
    }],
  ];
}

@end
