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
#import "FBElementUtils.h"
#import "FBMathUtils.h"
#import "FBXCodeCompatibility.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUtilities.h"
#import "XCTestPrivateSymbols.h"

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

static NSMutableDictionary<NSNumber *, NSMutableDictionary<NSString *, NSNumber *> *> *fb_generationsCache;

+ (void)load
{
  fb_generationsCache = [NSMutableDictionary dictionary];
}

- (nullable NSNumber *)fb_cachedVisibilityValue
{
  NSNumber* generationObj = [NSNumber numberWithUnsignedLongLong:self.generation];
  NSDictionary<NSString *, NSNumber *> *result = [fb_generationsCache objectForKey:generationObj];
  if (nil == result) {
    // There is no need to keep the cached data for the previous generations
    [fb_generationsCache removeAllObjects];
    [fb_generationsCache setObject:[NSMutableDictionary dictionary] forKey:generationObj];
    return nil;
  }
  return [result objectForKey:[NSString stringWithFormat:@"%p", (void *)self]];
}

- (BOOL)fb_cacheVisibilityWithValue:(BOOL)isVisible forAncestors:(nullable NSArray<XCElementSnapshot *> *)ancestors
{
  NSMutableDictionary<NSString *, NSNumber *> *destination = [fb_generationsCache objectForKey:@(self.generation)];
  NSNumber *visibleObj = [NSNumber numberWithBool:isVisible];
  [destination setObject:visibleObj forKey:[NSString stringWithFormat:@"%p", (void *)self]];
  if (isVisible && nil != ancestors) {
    // if an element is visible then all its ancestors must be visible as well
    for (XCElementSnapshot *ancestor in ancestors) {
      NSString *ancestorId = [NSString stringWithFormat:@"%p", (void *)ancestor];
      if (nil == [destination objectForKey:ancestorId]) {
        [destination setObject:visibleObj forKey:ancestorId];
      }
    }
  }
  return isVisible;
}

- (CGRect)fb_frameInContainer:(XCElementSnapshot *)container hierarchyIntersection:(nullable NSValue *)intersectionRectange
{
  CGRect currentRectangle = nil == intersectionRectange ? self.frame : [intersectionRectange CGRectValue];
  XCElementSnapshot *parent = self.parent;
  CGRect parentFrame = parent.frame;
  CGRect intersectionWithParent = CGRectIntersection(currentRectangle, parentFrame);
  if (CGRectIsEmpty(intersectionWithParent) && parent != container) {
    if (CGSizeEqualToSize(parentFrame.size, CGSizeZero) &&
        CGPointEqualToPoint(parentFrame.origin, CGPointZero) &&
        parent.elementType == XCUIElementTypeOther) {
      // Special case (or XCTest bug). Skip such parent
      intersectionWithParent = currentRectangle;
    } else {
      CGSize containerSize = container.frame.size;
      CGRect selfFrame = self.frame;
      if (self.elementType == XCUIElementTypeOther) {
        // Special case (or XCTest bug). Shift the origin
        if (CGSizeEqualToSize(selfFrame.size, CGSizeZero)) {
          // Covers ActivityListView case
          currentRectangle.origin.x += parentFrame.origin.x;
          currentRectangle.origin.y += parentFrame.origin.y;
        } else if (CGSizeEqualToSize(parentFrame.size, containerSize) ||
                   // The size might be inverted in landscape
                   CGSizeEqualToSize(parentFrame.size, CGSizeMake(containerSize.height, containerSize.width))) {
          if (CGPointEqualToPoint(parentFrame.origin, CGPointZero)) {
            // Covers ScrollView case
            currentRectangle.origin.x -= selfFrame.origin.x;
            currentRectangle.origin.y -= selfFrame.origin.y;
          } else {
            // Covers RemoteBridgeView case
            currentRectangle.origin.x += parentFrame.origin.x;
            currentRectangle.origin.y += parentFrame.origin.y;
          }
        }
        intersectionWithParent = CGRectIntersection(currentRectangle, parentFrame);
      }
    }
  }
  if (CGRectIsEmpty(intersectionWithParent) || parent == container) {
    return intersectionWithParent;
  }
  return [parent fb_frameInContainer:container hierarchyIntersection:[NSValue valueWithCGRect:intersectionWithParent]];
}

- (CGRect)fb_frameInWindow
{
  NSArray<XCElementSnapshot *> *ancestors = self.fb_ancestors;
  XCElementSnapshot *parentWindow = ancestors.count > 1 ? [ancestors objectAtIndex:ancestors.count - 2] : nil;
  if (nil == parentWindow) {
    return self.frame;
  }
  return [self fb_frameInContainer:parentWindow hierarchyIntersection:nil];
}

- (BOOL)fb_hasAnyVisibleLeafs
{
  NSArray<XCElementSnapshot *> *children = self.children;
  if (0 == children.count) {
    return self.fb_isVisible;
  }
  
  for (XCElementSnapshot *child in children) {
    if (child.fb_hasAnyVisibleLeafs) {
      return YES;
    }
  }
  
  return NO;
}

- (BOOL)fb_isVisible
{
  NSNumber *cachedValue = [self fb_cachedVisibilityValue];
  if (nil != cachedValue) {
    return [cachedValue boolValue];
  }
  
  CGRect selfFrame = self.frame;
  if (CGRectIsEmpty(selfFrame)) {
    return [self fb_cacheVisibilityWithValue:NO forAncestors:nil];
  }
  
  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    BOOL isVisible = [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
    return [self fb_cacheVisibilityWithValue:isVisible forAncestors:nil];
  }
  
  NSArray<XCElementSnapshot *> *ancestors = self.fb_ancestors;
  XCElementSnapshot *parentWindow = ancestors.count > 1 ? [ancestors objectAtIndex:ancestors.count - 2] : nil;
  XCElementSnapshot *appElement = ancestors.count > 0 ? [ancestors lastObject] : self;
  
  CGRect appFrame = appElement.frame;
  CGRect rectInContainer = nil == parentWindow ? selfFrame : [self fb_frameInContainer:parentWindow hierarchyIntersection:nil];
  if (CGRectIsEmpty(rectInContainer)) {
    return [self fb_cacheVisibilityWithValue:NO forAncestors:ancestors];
  }
  CGPoint midPoint = CGPointMake(rectInContainer.origin.x + rectInContainer.size.width / 2,
                                 rectInContainer.origin.y + rectInContainer.size.height / 2);
  CGRect windowFrame = nil == parentWindow ? selfFrame : parentWindow.frame;
  if ((appFrame.size.height > appFrame.size.width && windowFrame.size.height < windowFrame.size.width) ||
      (appFrame.size.height < appFrame.size.width && windowFrame.size.height > windowFrame.size.width)) {
    // This is the indication of the fact that transformation is broken and coordinates should be
    // recalculated manually.
    // However, upside-down case cannot be covered this way, which is not important for Appium
    midPoint = FBInvertPointForApplication(midPoint, appFrame.size, FBApplication.fb_activeApplication.interfaceOrientation);
  }
  XCElementSnapshot *hitElement = [self hitTest:midPoint];
  if (nil != hitElement && (self == hitElement || [ancestors containsObject:hitElement])) {
    return [self fb_cacheVisibilityWithValue:YES forAncestors:ancestors];
  }
  if (self.children.count > 0) {
    if (nil != hitElement && [self._allDescendants containsObject:hitElement]) {
      return [hitElement fb_cacheVisibilityWithValue:YES forAncestors:hitElement.fb_ancestors];
    }
    if (self.fb_hasAnyVisibleLeafs) {
      return [self fb_cacheVisibilityWithValue:YES forAncestors:ancestors];
    }
  } else if (nil == hitElement) {
    // Sometimes XCTest returns nil for leaf elements hit test even if such elements are hittable
    // Assume such elements are visible if their rectInContainer is visible
    return [self fb_cacheVisibilityWithValue:YES forAncestors:ancestors];
  }
  return [self fb_cacheVisibilityWithValue:NO forAncestors:ancestors];
}

@end
