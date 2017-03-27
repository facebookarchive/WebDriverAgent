/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBWebDriverAttributes.h"

#import <objc/runtime.h>

#import "FBElementTypeTransformer.h"
#import "FBMacros.h"
#import "XCUIElement+FBAccessibility.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement.h"
#import "FBElementUtils.h"

@implementation XCUIElement (WebDriverAttributesForwarding)

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  struct objc_method_description descr = protocol_getMethodDescription(@protocol(FBElement), aSelector, YES, YES);
  BOOL isWebDriverAttributesSelector = descr.name != nil;
  if(!isWebDriverAttributesSelector) {
    return nil;
  }
  if (!self.exists) {
    return [XCElementSnapshot new];
  }

  if (self.lastSnapshot) {
    return self.lastSnapshot;
  }
  // If lastSnapshot is missing, trying to resolve it.
  [self resolve];

  // If lastSnapshot is still missing aplication is probably not active. Returning empty element instead of crashing.
  // This will work well, if element search is requested (will not match anything) and reqesting properties values (will return nils).
  return self.lastSnapshot ?: [XCElementSnapshot new];
}

@end


@implementation XCElementSnapshot (WebDriverAttributes)

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:[FBElementUtils wdAttributeNameForAttributeName:name]];
}

- (id)wdValue
{
  id value = self.value;
  if (self.elementType == XCUIElementTypeStaticText) {
    value = FBFirstNonEmptyValue(self.value, self.label);
  }
  if (self.elementType == XCUIElementTypeButton) {
    value = FBFirstNonEmptyValue(self.value, (self.isSelected ? @YES : nil));
  }
  if (self.elementType == XCUIElementTypeSwitch) {
    value = @([self.value boolValue]);
  }
  if (self.elementType == XCUIElementTypeTextView ||
      self.elementType == XCUIElementTypeTextField ||
      self.elementType == XCUIElementTypeSecureTextField) {
    value = FBFirstNonEmptyValue(self.value, self.placeholderValue);
  }
  return FBTransferEmptyStringToNil(value);
}

- (NSString *)wdName
{
  return FBTransferEmptyStringToNil(FBFirstNonEmptyValue(self.identifier, self.label));
}

- (NSString *)wdLabel
{
  if (self.elementType == XCUIElementTypeTextField) {
    return self.label;
  }
  return FBTransferEmptyStringToNil(self.label);
}

- (NSString *)wdType
{
  return [FBElementTypeTransformer stringWithElementType:self.elementType];
}

- (CGRect)wdFrame
{
  return CGRectIntegral(self.frame);
}

- (BOOL)isWDVisible
{
  return self.fb_isVisible;
}

- (BOOL)isWDAccessible
{
  // Special cases:
  // Table view cell: we consider it accessible if it's container is accessible
  // Text fields: actual accessible element isn't text field itself, but nested element
  if (self.elementType == XCUIElementTypeCell) {
    if (!self.fb_isAccessibilityElement) {
      XCElementSnapshot *containerView = [[self children] firstObject];
      if (!containerView.fb_isAccessibilityElement) {
        return NO;
      }
    }
  } else if (self.elementType != XCUIElementTypeTextField && self.elementType != XCUIElementTypeSecureTextField) {
    if (!self.fb_isAccessibilityElement) {
      return NO;
    }
  }
  XCElementSnapshot *parentSnapshot = self.parent;
  while (parentSnapshot) {
    // In the scenario when table provides Search results controller, table could be marked as accessible element, even though it isn't
    // As it is highly unlikely that table view should ever be an accessibility element itself,
    // for now we work around that by skipping Table View in container checks
    if (parentSnapshot.fb_isAccessibilityElement && parentSnapshot.elementType != XCUIElementTypeTable) {
      return NO;
    }
    parentSnapshot = parentSnapshot.parent;
  }
  return YES;
}

- (BOOL)isWDAccessibilityContainer
{
  for (XCElementSnapshot *child in self.children) {
    if (child.isWDAccessibilityContainer || child.fb_isAccessibilityElement) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isWDEnabled
{
  return self.isEnabled;
}

- (NSDictionary *)wdRect
{
  CGRect frame = self.wdFrame;
  return @{
    @"x": @(CGRectGetMinX(frame)),
    @"y": @(CGRectGetMinY(frame)),
    @"width": @(CGRectGetWidth(frame)),
    @"height": @(CGRectGetHeight(frame)),
  };
}

@end
