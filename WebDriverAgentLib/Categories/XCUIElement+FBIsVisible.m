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
#import "XCElementSnapshot+FBHitPoint.h"

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  return self.fb_lastSnapshot.fb_isVisible;
}

- (CGRect)fb_frameInWindow
{
  return self.fb_lastSnapshot.fb_frameInWindow;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

- (CGRect)fb_frameInContainer:(XCElementSnapshot *)container hierarchyIntersection:(nullable NSValue *)intersectionRectange
{
  CGRect currentRectangle = nil == intersectionRectange ? self.frame : [intersectionRectange CGRectValue];
  XCElementSnapshot *parent = self.parent;
  CGRect intersectionWithParent = CGRectIntersection(currentRectangle, parent.frame);
  if (CGRectIsEmpty(intersectionWithParent) || parent == container) {
    return intersectionWithParent;
  }
  return [parent fb_frameInContainer:container hierarchyIntersection:[NSValue valueWithCGRect:intersectionWithParent]];
}

- (CGRect)fb_frameInWindow
{
  XCElementSnapshot *parentWindow = [self fb_parentMatchingType:XCUIElementTypeWindow];
  if (nil != parentWindow) {
    return [self fb_frameInContainer:parentWindow hierarchyIntersection:nil];
  }
  return self.frame;
}

- (BOOL)fb_isVisible
{
  CGRect frame = self.frame;
  if (CGRectIsEmpty(frame)) {
    return NO;
  }

  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
  }

  XCElementSnapshot *parentWindow = [self fb_parentMatchingType:XCUIElementTypeWindow];
  if (nil != parentWindow &&
      CGRectIsEmpty([self fb_frameInContainer:parentWindow hierarchyIntersection:nil])) {
    return NO;
  }
  
  CGRect appFrame = [self fb_rootElement].frame;
  
  CGPoint midPoint = [self.suggestedHitpoints.lastObject CGPointValue];
  if (!CGRectEqualToRect(appFrame, nil == parentWindow ? frame : parentWindow.frame)) {
    midPoint = FBInvertPointForApplication(midPoint, appFrame.size, FBApplication.fb_activeApplication.interfaceOrientation);
  }
  XCElementSnapshot *hitElement = [self hitTest:midPoint];
  if (self == hitElement || [self._allDescendants.copy containsObject:hitElement]) {
    return YES;
  }
  
  if (CGRectContainsPoint(appFrame, self.fb_hitPoint)) {
    return YES;
  }
  for (XCElementSnapshot *elementSnapshot in self.children.copy) {
    if (elementSnapshot.fb_isVisible) {
      return YES;
    }
  }

  return NO;
}

@end
