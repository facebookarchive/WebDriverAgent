/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBForceTouch.h"

#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "XCUIElement+FBUtilities.h"
#import "XCEventGenerator.h"
#import "XCSynthesizedEventRecord.h"
#import "XCElementSnapshot+FBHitPoint.h"
#import "XCPointerEventPath.h"
#import "XCTRunnerDaemonSession.h"

@implementation XCUIElement (FBForceTouch)

- (BOOL)fb_forceTouchWithError:(NSError **)error
{
  XCElementSnapshot *snapshot = self.fb_lastSnapshot;
  CGPoint hitpoint = snapshot.fb_hitPoint;
  if (CGPointEqualToPoint(hitpoint, CGPointMake(-1, -1))) {
    hitpoint = [snapshot.suggestedHitpoints.lastObject CGPointValue];
  }
  return [self fb_performFourceTouchAtPoint:hitpoint error:error];
}

- (BOOL)fb_performFourceTouchAtPoint:(CGPoint)hitPoint error:(NSError *__autoreleasing*)error
{
  [self fb_waitUntilFrameIsStable];
  __block BOOL didSucceed;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
    [[XCEventGenerator sharedGenerator] forcePressAtPoint:hitPoint orientation:self.interfaceOrientation handler:^{
      didSucceed = YES;
      completion();
    }];
  }];
  return didSucceed;
}

@end
