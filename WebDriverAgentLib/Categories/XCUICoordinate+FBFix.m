/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUICoordinate+FBFix.h"

#import "XCUICoordinate.h"
#import "XCUIElement+FBUtilities.h"
#import "XCElementSnapshot+FBHitPoint.h"

@implementation XCUICoordinate (FBFix)

- (CGPoint)fb_screenPoint
{
  CGPoint referencePoint = CGPointMake(0, 0);
  if (self.element) {
    CGRect frame = self.element.frame;
    referencePoint = CGPointMake(
      CGRectGetMinX(frame) + CGRectGetWidth(frame) * self.normalizedOffset.dx,
      CGRectGetMinY(frame) + CGRectGetHeight(frame) * self.normalizedOffset.dy);
  }
  else if (self.coordinate) {
    referencePoint = self.coordinate.fb_screenPoint;
  }
  CGPoint screenPoint = CGPointMake(
    referencePoint.x + self.pointsOffset.dx,
    referencePoint.y + self.pointsOffset.dy);
  CGRect rect = self.referencedElement.frame;
  return CGPointMake(
    MIN(CGRectGetMaxX(rect), screenPoint.x),
    MIN(CGRectGetMaxY(rect), screenPoint.y));
}

@end
