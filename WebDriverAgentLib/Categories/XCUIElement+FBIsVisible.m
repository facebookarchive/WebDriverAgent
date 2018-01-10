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
      [destination setObject:visibleObj forKey:[NSString stringWithFormat:@"%p", (void *)ancestor]];
    }
  }
  return isVisible;
}

- (CGRect)fb_frameInContainer:(XCElementSnapshot *)container hierarchyIntersection:(nullable NSValue *)intersectionRectange
{
  CGRect currentRectangle = nil == intersectionRectange ? self.frame : [intersectionRectange CGRectValue];
  XCElementSnapshot *parent = self.parent;
  CGRect parentFrame = parent.frame;
  CGRect intersectionWithParent = CGRectIntersection(currentRectangle, parent.frame);
  if (CGRectIsEmpty(intersectionWithParent) && parent != container) {
    CGSize containerSize = container.frame.size;
    if ((CGSizeEqualToSize(parentFrame.size, containerSize) ||
         // The size might be inverted in landscape
         CGSizeEqualToSize(parentFrame.size, CGSizeMake(containerSize.height, containerSize.width))) &&
        parent.elementType == XCUIElementTypeOther) {
      // Special case (or XCTest bug). We need to shift the origin
      currentRectangle.origin.x += parentFrame.origin.x;
      currentRectangle.origin.y += parentFrame.origin.y;
      intersectionWithParent = CGRectIntersection(currentRectangle, parentFrame);
    }
    if (CGSizeEqualToSize(parentFrame.size, CGSizeZero) &&
        CGPointEqualToPoint(parentFrame.origin, CGPointZero) &&
        parent.elementType == XCUIElementTypeOther) {
      // Special case (or XCTest bug). Skip such parent
      intersectionWithParent = currentRectangle;
    }
  }
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
  
  CGRect frame = self.frame;
  if (CGRectIsEmpty(frame)) {
    return [self fb_cacheVisibilityWithValue:NO forAncestors:nil];
  }
  
  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    BOOL isVisible = [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
    return [self fb_cacheVisibilityWithValue:isVisible forAncestors:nil];
  }
  
  XCElementSnapshot *parentWindow = nil;
  NSMutableArray<XCElementSnapshot *> *ancestorsUntilWindow = [NSMutableArray array];
  XCElementSnapshot *parent = self.parent;
  while (parent) {
    XCUIElementType type = parent.elementType;
    if (type == XCUIElementTypeWindow) {
      parentWindow = parent;
      break;
    }
    [ancestorsUntilWindow addObject:parent];
    parent = parent.parent;
  }
  if (nil == parentWindow) {
    [ancestorsUntilWindow removeAllObjects];
  }
  
  CGRect appFrame = [self fb_rootElement].frame;
  CGRect rectInContainer = nil == parentWindow ? self.frame : [self fb_frameInContainer:parentWindow hierarchyIntersection:nil];
  if (CGRectIsEmpty(rectInContainer)) {
    return [self fb_cacheVisibilityWithValue:NO forAncestors:ancestorsUntilWindow];
  }
  BOOL hasChilren = self.children.count > 0;
  if (hasChilren && self.fb_hasAnyVisibleLeafs) {
    return [self fb_cacheVisibilityWithValue:YES forAncestors:ancestorsUntilWindow];
  }
  CGPoint midPoint = CGPointMake(rectInContainer.origin.x + rectInContainer.size.width / 2,
                                 rectInContainer.origin.y + rectInContainer.size.height / 2);
  CGRect parentWindowFrame = parentWindow.frame;
  if ((appFrame.size.height > appFrame.size.width && parentWindowFrame.size.height < parentWindowFrame.size.width) ||
      (appFrame.size.height < appFrame.size.width && parentWindowFrame.size.height > parentWindowFrame.size.width)) {
    // This is the indication of the fact that transformation is broken and coordinates should be
    // recalculated manually.
    // However, upside-down case cannot be covered this way, which is not important for Appium
    midPoint = FBInvertPointForApplication(midPoint, appFrame.size, FBApplication.fb_activeApplication.interfaceOrientation);
  }
  XCElementSnapshot *hitElement = [self hitTest:midPoint];
  if (nil == hitElement || self == hitElement || [ancestorsUntilWindow containsObject:hitElement] ||
      (hasChilren && [self._allDescendants containsObject:hitElement])) {
    return [self fb_cacheVisibilityWithValue:YES forAncestors:ancestorsUntilWindow];
  }
  return [self fb_cacheVisibilityWithValue:NO forAncestors:ancestorsUntilWindow];
}

@end

