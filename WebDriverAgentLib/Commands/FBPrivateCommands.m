/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBPrivateCommands.h"

#import "FBApplication.h"
#import "FBKeyboard.h"
#import "FBPredicate.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBErrorBuilder.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBRuntimeUtils.h"
#import "NSPredicate+FBFormat.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBPickerWheel.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBTyping.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "FBElementTypeTransformer.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "XCEventGenerator.h"

@implementation QXPrivateCommands
+ (NSArray *)routes{
  return
  @[
    [[FBRoute POST:@"/private/tap"] respondWithTarget:self action:@selector(handlePrivateTap:)],
    [[FBRoute POST:@"/private/swipe"] respondWithTarget:self action:@selector(handlePrivateSwipe:)],
    [[FBRoute POST:@"/private/pinch"] respondWithTarget:self action:@selector(handlePrivatePinch:)],
    [[FBRoute POST:@"/private/touchAndHold"] respondWithTarget:self action:@selector(handlePrivateTouchAndHold:)],
    ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handlePrivateTap:(FBRouteRequest *)request {
  FBApplication *application = request.session.application;
  CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  if (isSDKVersionLessThan(@"11.0")) {
    tapPoint = FBInvertPointForApplication(tapPoint, application.frame.size, application.interfaceOrientation);
  }
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:application normalizedOffset:CGVectorMake(0, 0)];
  tapPoint = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(tapPoint.x, tapPoint.y)].screenPoint;
  dispatch_semaphore_t t = dispatch_semaphore_create(0);
  [[XCEventGenerator sharedGenerator] pressAtPoint:tapPoint forDuration:0 orientation:application.interfaceOrientation handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    dispatch_semaphore_signal(t);
  }];
  dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER);
  return FBResponseWithOK();
}


+ (id<FBResponsePayload>)handlePrivateSwipe:(FBRouteRequest *)request{
  FBApplication *application = request.session.application;
  CGPoint fromPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  CGPoint toPoint = CGPointMake((CGFloat)[request.arguments[@"x1"] doubleValue], (CGFloat)[request.arguments[@"y1"] doubleValue]);
  if (isSDKVersionLessThan(@"11.0")) {
    fromPoint = FBInvertPointForApplication(fromPoint, application.frame.size, application.interfaceOrientation);
    toPoint = FBInvertPointForApplication(toPoint, application.frame.size, application.interfaceOrientation);
  }
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:application normalizedOffset:CGVectorMake(0, 0)];
  fromPoint = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(fromPoint.x, fromPoint.y)].screenPoint;
  toPoint = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(toPoint.x, toPoint.y)].screenPoint;
  
  dispatch_semaphore_t t = dispatch_semaphore_create(0);
  [[XCEventGenerator sharedGenerator] pressAtPoint:fromPoint forDuration:[request.arguments[@"duration"] doubleValue] liftAtPoint:toPoint velocity:1000 orientation:application.interfaceOrientation name:@"MonkeySwipe" handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    dispatch_semaphore_signal(t);
  }];
  dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER);
  return FBResponseWithOK();
}


+ (id<FBResponsePayload>)handlePrivatePinch:(FBRouteRequest *)request{
  FBApplication *application = request.session.application;
  CGRect rect = CGRectMake((CGFloat)[request.arguments[@"x"] doubleValue],
                           (CGFloat)[request.arguments[@"y"] doubleValue],
                           (CGFloat)[request.arguments[@"width"] doubleValue],
                           (CGFloat)[request.arguments[@"height"] doubleValue]);
  
  dispatch_semaphore_t t = dispatch_semaphore_create(0);
  [[XCEventGenerator sharedGenerator] pinchInRect:rect withScale:[request.arguments[@"scale"] doubleValue] velocity:1000 orientation:application.interfaceOrientation handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    dispatch_semaphore_signal(t);
  }];
  dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER);
  return FBResponseWithOK();
}


+ (id<FBResponsePayload>)handlePrivateTouchAndHold:(FBRouteRequest *)request{
  FBApplication *application = request.session.application;
  CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  
  dispatch_semaphore_t t = dispatch_semaphore_create(0);
  [[XCEventGenerator sharedGenerator] pressAtPoint:tapPoint forDuration:[request.arguments[@"duration"] doubleValue] orientation:application.interfaceOrientation handler:^(XCSynthesizedEventRecord *record, NSError *error) {
    dispatch_semaphore_signal(t);
  }];
  dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER);
  return FBResponseWithOK();
}

@end
