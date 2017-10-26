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
#import "FBXCodeCompatibility.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUtilities.h"
#import "XCTestPrivateSymbols.h"
#import <XCTest/XCUIDevice.h>

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  return self.fb_lastSnapshot.fb_isVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

- (BOOL)fb_isVisible
{
  CGRect frame = self.frame;
  if (CGRectIsEmpty(frame)) {
    return NO;
  }
  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
  }
  CGRect appFrame = [self fb_rootElement].frame;
  CGSize screenSize = FBAdjustDimensionsForApplication(appFrame.size, (UIInterfaceOrientation)[XCUIDevice sharedDevice].orientation);
  CGRect screenFrame = CGRectMake(0, 0, screenSize.width, screenSize.height);
  if (!CGRectIntersectsRect(frame, screenFrame)) {
    return NO;
  }
  CGPoint midPoint;
  @try {	
    midPoint = [self hitPoint];
  } @catch (NSException *e) {
    [FBLogger logFmt:@"Failed to fetch hit point for %@ - %@", self.debugDescription, e.reason];
    midPoint = [self.suggestedHitpoints.lastObject CGPointValue];
  }
  XCElementSnapshot *hitElement = [self hitTest:midPoint];
  if (self == hitElement || [self._allDescendants.copy containsObject:hitElement]) {
    return YES;
  }
  return NO;
}

@end
