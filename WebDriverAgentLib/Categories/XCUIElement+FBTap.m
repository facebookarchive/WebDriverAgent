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
#import "XCElementSnapshot+FBHitPoint.h"

const CGFloat FBTapDuration = 0.01f;

@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  return [self fb_performTapAtPoint:self.fb_lastSnapshot.fb_hitPoint error:error];
}

- (BOOL)fb_tapCoordinate:(CGPoint)relativeCoordinate error:(NSError **)error
{
  CGPoint hitPoint = CGPointMake(self.frame.origin.x + relativeCoordinate.x, self.frame.origin.y + relativeCoordinate.y);
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    /*
     Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
     even if the device is not in portait mode. That is why we need to recalculate them manually
     based on the current orientation value
     */
    hitPoint = FBInvertPointForApplication(hitPoint, self.application.frame.size, self.application.interfaceOrientation);
  }
  return [self fb_performTapAtPoint:hitPoint error:error];
}

- (BOOL)fb_performTapAtPoint:(CGPoint)hitPoint error:(NSError *__autoreleasing*)error
{
  [self fb_waitUntilFrameIsStable];
  __block BOOL didSucceed;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)()){
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

    // Xcode 10.2 and below
    XCEventGenerator *eventGenerator = [XCEventGenerator sharedGenerator];
    if ([eventGenerator respondsToSelector:@selector(tapAtTouchLocations:numberOfTaps:orientation:handler:)]) {
      [eventGenerator tapAtTouchLocations:@[[NSValue valueWithCGPoint:hitPoint]] numberOfTaps:1 orientation:self.interfaceOrientation handler:handlerBlock];
    } else {
      [eventGenerator tapAtPoint:hitPoint orientation:self.interfaceOrientation handler:handlerBlock];
    }
  }];
  return didSucceed;
}

@end
