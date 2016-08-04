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

#import "FBApplication.h"
#import "FBKeyboard.h"
#import "FBResponsePayload.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBSpringboardApplication.h"
#import "XCUIApplication+FBHelpers.h"
#import "XCUIDevice+FBHelpers.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "XCUIElement+FBScrolling.h"

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/homescreen"].withoutSession respondWithTarget:self action:@selector(handleHomescreenCommand:)],
    [[FBRoute POST:@"/deactivateApp"] respondWithTarget:self action:@selector(handleDeactivateAppCommand:)],
    [[FBRoute POST:@"/timeouts"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/scroll"] respondWithTarget:self action:@selector(handleScrollCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleHomescreenCommand:(FBRouteRequest *)request
{
  NSError *error;
  if (![[XCUIDevice sharedDevice] fb_goToHomescreenWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDeactivateAppCommand:(FBRouteRequest *)request
{
  NSNumber *requestedDuration = request.arguments[@"duration"];
  NSTimeInterval duration = (requestedDuration ? requestedDuration.doubleValue : 3.);
  NSError *error;
  if (![request.session.application fb_deactivateWithDuration:duration error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTimeouts:(FBRouteRequest *)request
{
  // This method is intentionally not supported.
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScrollCommand:(FBRouteRequest *)request
{
    NSString *const direction = request.arguments[@"direction"];
    if (direction) {
        if ([direction isEqualToString:@"up"]) {
            [request.session.application fb_scrollUp];
        } else if ([direction isEqualToString:@"down"]) {
            [request.session.application fb_scrollDown];
        } else if ([direction isEqualToString:@"left"]) {
            [request.session.application fb_scrollLeft];
        } else if ([direction isEqualToString:@"right"]) {
            [request.session.application fb_scrollRight];
        } else {
            return FBResponseWithErrorFormat(@"Unsupported scroll type");
        }
        return FBResponseWithOK();
    } else {
        return FBResponseWithErrorFormat(@"Missing direction parameter");
    }
}

@end
