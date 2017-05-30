/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBIsVisible.h"

#import "FBApplication.h"
#import "FBConfiguration.h"
#import "FBMathUtils.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUtilities.h"
#import "XCTestPrivateSymbols.h"
#import <XCTest/XCUIDevice.h>
#import "XCElementSnapshot+FBHitPoint.h"

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  return self.fb_lastSnapshot.fb_isVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)
- (BOOL)fb_isVisible
{
  return [self fb_isVisible:NO];
}

- (BOOL)fb_isVisible: (BOOL)useHeuristic
{
  CGRect frame = self.frame;
  if (CGRectIsEmpty(frame)) {
    return NO;
  }
  CGRect visibleFrame = useHeuristic ? frame : self.visibleFrame;
  if (CGRectIsEmpty(visibleFrame)) {
    return NO;
  }
  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
  }
  XCElementSnapshot *app = [self _rootElement];
  CGSize screenSize = FBAdjustDimensionsForApplication(app.frame.size, (UIInterfaceOrientation)[XCUIDevice sharedDevice].orientation);
  CGRect screenFrame = CGRectMake(0, 0, screenSize.width, screenSize.height);
  BOOL rectIntersects = CGRectIntersectsRect(visibleFrame, screenFrame);
  BOOL isActionable = useHeuristic ? YES : CGRectContainsPoint(app.frame, self.fb_hitPoint);
  return rectIntersects && isActionable;
}

@end
