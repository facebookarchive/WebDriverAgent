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
#import "FBXCodeCompatibility.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCElementSnapshot+FBHitPoint.h"
#import "XCTestPrivateSymbols.h"
#import "XCUIElement+FBUtilities.h"

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  return self.fb_lastSnapshot.fb_isVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

+ (BOOL)fb_isVisibleInContainerWindow:(XCElementSnapshot *)window selfElement:(XCElementSnapshot *)element hierarchyIntersection:(nullable NSValue *)intersectionRectange appFrame:(CGRect)appFrame
{
  CGRect currentRectangle = nil == intersectionRectange ? element.frame : [intersectionRectange CGRectValue];
  XCElementSnapshot *parent = element.parent;
  CGRect intersectionWithParent = CGRectIntersection(currentRectangle, parent.frame);
  if (CGRectIsEmpty(intersectionWithParent)) {
    return NO;
  }
  if (parent == window) {
    // Assume the element is visible if its root container is hittable and the frame is onscreen
    return CGRectContainsPoint(appFrame, element.fb_hitPoint);
  }
  return [self.class fb_isVisibleInContainerWindow:window selfElement:parent hierarchyIntersection:[NSValue valueWithCGRect:intersectionWithParent] appFrame:appFrame];
}

- (BOOL)fb_isVisible
{
  if (CGRectIsEmpty(self.frame)) {
    return NO;
  }
  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
  }
  CGRect appFrame = [self fb_rootElement].frame;
  XCElementSnapshot *containerWindow = [self fb_parentMatchingType:XCUIElementTypeWindow];
  if (nil != containerWindow) {
    return [self.class fb_isVisibleInContainerWindow:containerWindow selfElement:self hierarchyIntersection:nil appFrame:appFrame];
  }
  return CGRectContainsPoint(appFrame, self.fb_hitPoint);
}

@end
