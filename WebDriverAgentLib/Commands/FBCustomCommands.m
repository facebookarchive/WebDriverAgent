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

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/homescreen"].withoutSession respondWithTarget:self action:@selector(handleHomescreenCommand:)],
    [[FBRoute POST:@"/deactivateApp"] respondWithTarget:self action:@selector(handleDeactivateAppCommand:)],
    [[FBRoute POST:@"/timeouts/implicit_wait"] respondWithTarget:self action:@selector(handleImplicitWaitCommand:)],
    [[FBRoute POST:@"/hide_keyboard"] respondWithTarget:self action:@selector(handleHideKeyboard:)]
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleHomescreenCommand:(FBRouteRequest *)request
{
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleDeactivateAppCommand:(FBRouteRequest *)request
{
  NSString *applicationIdentifier = request.session.application.label;

  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];

  NSNumber *requestedDuration = request.arguments[@"duration"];
  CGFloat duration = (requestedDuration ? requestedDuration.floatValue : 3.f);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];

  NSError *error;
  if (![[FBSpringboardApplication springboard] fb_tapApplicationWithIdentifier:applicationIdentifier error:&error]) {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
  }
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleImplicitWaitCommand:(FBRouteRequest *)request
{
  // This method is intentionally not supported.
  return FBResponseDictionaryWithOK();
}

+ (id<FBResponsePayload>)handleHideKeyboard:(FBRouteRequest *)request
{
    FBSession *session = request.session;
    XCUIElement *element = [session.application.windows elementBoundByIndex:0];
    XCUIElementQuery *allElements = [element descendantsMatchingType:XCUIElementTypeAny];
    XCUIElement *activeElement = [allElements elementMatchingPredicate:[NSPredicate predicateWithFormat:@"hasKeyboardFocus == YES"]];
    if ([activeElement exists]) {
        [element tap];
        return FBResponseDictionaryWithOK();
    } else {
        return FBResponseDictionaryWithStatus(FBCommandStatusInvalidElementState, nil);
    }

}

@end
