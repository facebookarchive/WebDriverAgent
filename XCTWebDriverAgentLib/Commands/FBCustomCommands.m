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

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/session/:sessionID/deactivateApp"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/timeouts/implicit_wait"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      // This method is intentionally not supported.
      return FBResponseDictionaryWithOK();
    }],
  ];
}

@end
