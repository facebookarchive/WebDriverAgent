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
#import "FBResponsePayload.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBSpringboardApplication.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

static const NSTimeInterval FBHomeButtonCoolOffTime = 1.;

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/homescreen"].withoutSession respondWithTarget:self action:@selector(handleHomescreenCommand:)],
    [[FBRoute POST:@"/deactivateApp"] respondWithTarget:self action:@selector(handleDeactivateAppCommand:)],
    //TODO: Remove once clients have been migrated.
    [[FBRoute POST:@"/timeouts/implicit_wait"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/timeouts"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/hide_keyboard"] respondWithTarget:self action:@selector(handleHideKeyboard:)]
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleHomescreenCommand:(FBRouteRequest *)request
{
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  // This is terrible workaround to the fact that pressButton:XCUIDeviceButtonHome is not a synchronous action.
  // On 9.2 some first queries  will trigger additional "go to home" event
  // So if we don't wait here it will be interpreted as double home button gesture and go to application switcher instead.
  // On 9.3 pressButton:XCUIDeviceButtonHome can be slightly delayed.
  // Causing waitUntilApplicationBoardIsVisible not to work properly in some edge cases e.g. like starting session right after this call, while being on home screen
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBHomeButtonCoolOffTime]];
  NSError *error;
  if (![[FBSpringboardApplication springboard] waitUntilApplicationBoardIsVisible:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDeactivateAppCommand:(FBRouteRequest *)request
{
  NSString *applicationIdentifier = request.session.application.label;

  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];

  NSNumber *requestedDuration = request.arguments[@"duration"];
  NSTimeInterval duration = (requestedDuration ? requestedDuration.doubleValue : 3.);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];

  NSError *error;
  if (![[FBSpringboardApplication springboard] fb_tapApplicationWithIdentifier:applicationIdentifier error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTimeouts:(FBRouteRequest *)request
{
  // This method is intentionally not supported.
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleHideKeyboard:(FBRouteRequest *)request
{
    FBSession *session = request.session;
    XCUIElement *element = [session.application.windows elementBoundByIndex:0];
    XCUIElementQuery *allElements = [element descendantsMatchingType:XCUIElementTypeAny];
    XCUIElement *activeElement = [allElements elementMatchingPredicate:[NSPredicate predicateWithFormat:@"hasKeyboardFocus == YES"]];
    if ([activeElement exists]) {
        [element tap];
        return FBResponseWithOK();
    } else {
        return FBResponseWithStatus(FBCommandStatusInvalidElementState, nil);
    }

}

@end
