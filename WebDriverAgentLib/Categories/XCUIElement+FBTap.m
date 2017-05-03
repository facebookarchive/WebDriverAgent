/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTap.h"

#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "XCUIElement+FBUtilities.h"
#import "XCEventGenerator.h"
#import "XCSynthesizedEventRecord.h"

@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  NSValue *hitpointValue = self.lastSnapshot.suggestedHitpoints.firstObject;
  if (nil == hitpointValue) {
    // hitPointCoordinate might not be the center of the element frame, it depends on the accessibilityActivationPoint
    CGPoint hitPoint = [self hitPointCoordinate].screenPoint;
    return [self fb_tapScreenCoordinate:hitPoint error:error];
  }
  CGPoint hitPoint = hitpointValue.CGPointValue;
  hitPoint.x -= self.frame.origin.x;
  hitPoint.y -= self.frame.origin.y;
  return [self fb_tapCoordinate:hitPoint error:error];
}

- (BOOL)fb_tapCoordinate:(CGPoint)relativeCoordinate error:(NSError **)error
{
  return [self fb_tapWithCoordinateBlock:^CGPoint {
      CGPoint hitPoint = CGPointMake(self.frame.origin.x + relativeCoordinate.x, self.frame.origin.y + relativeCoordinate.y);
      if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        /*
         Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
         even if the device is not in portait mode. That is why we need to recalculate them manually
         based on the current orientation value
         */
        hitPoint = FBInvertPointForApplication(hitPoint, self.application.frame.size, self.application.interfaceOrientation);
      }
      return hitPoint;
  } error:error];
}

- (BOOL)fb_tapScreenCoordinate:(CGPoint)absoluteCoordinate error:(NSError **)error
{
  return [self fb_tapWithCoordinateBlock:^CGPoint {
      return absoluteCoordinate;
  } error:error];
}

- (BOOL)fb_tapWithCoordinateBlock:(CGPoint (^)(void))coordinateBlock error:(NSError *__autoreleasing*)error
{
  [self fb_waitUntilFrameIsStable];
  __block BOOL didSucceed;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)()){
    CGPoint hitPoint = coordinateBlock();
    XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
      if (commandError) {
        [FBLogger logFmt:@"Failed to perform tap: %@", commandError];
      }
      if (error) {
        *error = commandError;
      }
      didSucceed = (commandError == nil);
      completion();
    };
    XCEventGenerator *eventGenerator = [XCEventGenerator sharedGenerator];
    if ([eventGenerator respondsToSelector:@selector(tapAtTouchLocations:numberOfTaps:orientation:handler:)]) {
      [eventGenerator tapAtTouchLocations:@[[NSValue valueWithCGPoint:hitPoint]] numberOfTaps:1 orientation:self.interfaceOrientation handler:handlerBlock];
    }
    else {
      [eventGenerator tapAtPoint:hitPoint orientation:self.interfaceOrientation handler:handlerBlock];
    }
  }];
  return didSucceed;
}

@end
