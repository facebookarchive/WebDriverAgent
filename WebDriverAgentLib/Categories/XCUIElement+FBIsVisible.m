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
#import "FBElementUtils.h"
#import "FBMathUtils.h"
#import "FBXCodeCompatibility.h"
#import "FBXCTestDaemonsProxy.h"
#import "XCAccessibilityElement.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUID.h"
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
  
  NSMutableArray<XCElementSnapshot *> *ancestorsUntilCell = [NSMutableArray array];
  XCElementSnapshot *parentWindow = nil;
  NSMutableArray<XCElementSnapshot *> *ancestors = [NSMutableArray array];
  XCElementSnapshot *parent = self.parent;
  while (parent) {
    XCUIElementType type = parent.elementType;
    if (type == XCUIElementTypeWindow) {
      parentWindow = parent;
      break;
    }
    [ancestors addObject:parent];
    if (type == XCUIElementTypeCell && 0 == ancestorsUntilCell.count) {
      [ancestorsUntilCell addObjectsFromArray:ancestors];
    }
    parent = parent.parent;
  }
  
  CGRect appFrame = [self fb_rootElement].frame;
  if (nil == parentWindow) {
    return CGRectContainsPoint(appFrame, self.fb_hitPoint);
  }
  CGRect rectInContainer = [self fb_frameInContainer:parentWindow hierarchyIntersection:nil];
  if (CGRectIsEmpty(rectInContainer)) {
    return NO;
  }
  if (self.elementType == XCUIElementTypeCell) {
    // Special case - detect visibility based on gesture recognizer presence
    return self.parent.fb_isVisible;
  }
  CGPoint visibleRectCenter = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
  XCElementSnapshot *mainWindow = [parentWindow.parent.children firstObject];
  if (!CGRectEqualToRect(mainWindow.frame, appFrame) || !CGRectContainsRect(mainWindow.frame, appFrame)) {
    // This is the indication of the fact that transformation is broken and coordinates should be
    // recalculated manually.
    // However, upside-down case cannot be covered this way, which is not important for Appium
    if (CGRectContainsRect(parentWindow.frame, appFrame) || CGRectEqualToRect(parentWindow.frame, appFrame)) {
      // Poor man's solution for the very broken cases, where it's uncear how to fix
      // coordinates transformation
      CGPoint hitPoint = self.fb_hitPoint;
      if (hitPoint.x >= 0 && hitPoint.y >= 0) {
        return YES;
      }
      // Special case - detect visibility based on gesture recognizer presence
      for (parent in ancestorsUntilCell) {
        hitPoint = parent.fb_hitPoint;
        if (hitPoint.x >= 0 && hitPoint.y >= 0) {
          return YES;
        }
      }
      return NO;
    }
    visibleRectCenter = FBInvertPointForApplication(visibleRectCenter, appFrame.size, FBApplication.fb_activeApplication.interfaceOrientation);
  }
  XCAccessibilityElement *match = [FBXCTestDaemonsProxy accessibilityElementAtPoint:visibleRectCenter error:NULL];
  if (nil == match) {
    return NO;
  }
  NSUInteger matchUID = [FBElementUtils uidWithAccessibilityElement:match];
  if (self.fb_uid == matchUID) {
    return YES;
  }
  for (XCElementSnapshot *descendant in self._allDescendants) {
    if (matchUID == [FBElementUtils uidWithAccessibilityElement:descendant.accessibilityElement]) {
      return YES;
    }
  }
  // Special case - detect visibility based on gesture recognizer presence
  for (parent in ancestorsUntilCell) {
    if (matchUID == [FBElementUtils uidWithAccessibilityElement:parent.accessibilityElement]) {
      return YES;
    }
  }
  return NO;
}

@end
