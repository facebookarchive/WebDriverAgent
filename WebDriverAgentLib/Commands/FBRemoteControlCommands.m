/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRemoteControlCommands.h"

#import <XCTest/XCUIRemote.h>

#import "FBRoute.h"
#import "FBRouteRequest.h"

@implementation FBRemoteControlCommands

#pragma mark - <FBCommandHandler>

+ (nonnull NSArray *)routes {
  return
  @[
    [[FBRoute POST:@"/remote/press/:button"].withoutSession respondWithTarget:self action:@selector(handlePress:)],
    ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handlePress:(FBRouteRequest *)request
{
  NSNumber *buttonId = request.parameters[@"button"];
  if([self isValid:buttonId]) {
    NSNumber *pressDuration = request.arguments[@"duration"] ?: @0;
    [[XCUIRemote sharedRemote] pressButton:buttonId.intValue forDuration: pressDuration.intValue];
    return FBResponseWithOK();
  } else {
    return FBResponseWithErrorFormat(@"Incorrect button id. Expected: 0-8.");
  }
}

+ (BOOL) isValid: (NSNumber *) buttonId {
  if (buttonId) {
    return buttonId.intValue >= 0 && buttonId.intValue <= 8;
  } else {
    return false;
  }
}

@end
