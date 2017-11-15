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
#import "XCUIElement+FBUtilities.h"
#import "XCTestPrivateSymbols.h"
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
  CGRect frame = self.frame;
  if (CGRectIsEmpty(frame)) {
    return NO;
  }

  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
  }
  XCElementSnapshot *parentWindow = [self fb_parentMatchingType:XCUIElementTypeWindow];
  // appFrame is always returned like the app is in portrait mode
  // and all the further tests internally assume the app is in portrait mode even
  // if it is in landscape. That is why we must get the parent's window frame in order
  // to check if it intersects with the corresponding element's frame
  if (nil != parentWindow && !CGRectIntersectsRect(frame, parentWindow.frame)) {
    return NO;
  }
  CGPoint midPoint = [self.suggestedHitpoints.lastObject CGPointValue];
  XCElementSnapshot *hitElement = [self hitTest:midPoint];
  if (self == hitElement || [self._allDescendants.copy containsObject:hitElement]) {
    return YES;
  }
  CGRect appFrame = [self fb_rootElement].frame;
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
