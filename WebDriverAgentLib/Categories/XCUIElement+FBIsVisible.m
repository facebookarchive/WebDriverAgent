/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBIsVisible.h"

#import "FBConfiguration.h"
#import "FBMathUtils.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCTestPrivateSymbols.h"

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  if (!self.lastSnapshot) {
    [self resolve];
  }
  return self.lastSnapshot.fb_isVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

- (BOOL)fb_isVisible
{
  if (CGRectIsEmpty(self.frame) || CGRectIsEmpty(self.visibleFrame)) {
    return NO;
  }
  if (FBConfiguration.sharedInstance.useAlternativeVisibilityDetection) {
    CGSize screenSize = FBAdjustDimensionsForApplication(self.application.frame.size, self.application.interfaceOrientation);
    return CGRectIntersectsRect(self.visibleFrame, CGRectMake(0, 0, screenSize.width, screenSize.height));
  }
  return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
}

@end
