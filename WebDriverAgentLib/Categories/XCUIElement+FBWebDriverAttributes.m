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
#import "XCUIElement+FBUID.h"
#import "XCUIElement.h"
#import "XCUIElement+FBUtilities.h"
#import "FBElementUtils.h"


NSString *wdValue(id<XCUIElementAttributes> self) {
  id value = self.value;
  XCUIElementType elementType = self.elementType;
  if (elementType == XCUIElementTypeStaticText) {
    value = FBFirstNonEmptyValue(value, self.label);
  }
  if (elementType == XCUIElementTypeButton) {
    value = FBFirstNonEmptyValue(value, (self.isSelected ? @YES : nil));
  }
  if (elementType == XCUIElementTypeSwitch) {
    value = @([value boolValue]);
  }
  if (elementType == XCUIElementTypeTextView ||
      elementType == XCUIElementTypeTextField ||
      elementType == XCUIElementTypeSecureTextField) {
    value = FBFirstNonEmptyValue(value, self.placeholderValue);
  }
  value = FBTransferEmptyStringToNil(value);
  if (value) {
    value = [NSString stringWithFormat:@"%@", value];
  }
  return value;
}

NSString *wdName(id<XCUIElementAttributes> self) {
  return FBTransferEmptyStringToNil(FBFirstNonEmptyValue(self.identifier, self.label));
}

NSString *wdLabel(id<XCUIElementAttributes> self) {
  if (self.elementType == XCUIElementTypeTextField) {
    return self.label;
  }
  return FBTransferEmptyStringToNil(self.label);
}

NSString *wdType(id<XCUIElementAttributes> self) {
  return [FBElementTypeTransformer stringWithElementType:self.elementType];
}

CGRect wdFrame(id<XCUIElementAttributes> self) {
  return CGRectIntegral(self.frame);
}

NSDictionary *wdRect(id<XCUIElementAttributes> self) {
  CGRect frame = wdFrame(self);
  return @{
           @"x": @(CGRectGetMinX(frame)),
           @"y": @(CGRectGetMinY(frame)),
           @"width": @(CGRectGetWidth(frame)),
           @"height": @(CGRectGetHeight(frame)),
           };
}

BOOL isWDEnabled(id<XCUIElementAttributes> self) {
  return self.isEnabled;
}


@implementation XCUIElement (WebDriverAttributes)

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:[FBElementUtils wdAttributeNameForAttributeName:name]];
}

- (NSString *)wdValue
{
  return wdValue(self);
}

- (NSString *)wdName
{
  return wdName(self);
}

- (NSString *)wdLabel
{
  return wdLabel(self);
}

- (NSString *)wdType
{
  return wdType(self);
}

- (NSUInteger)wdUID
{
  return self.fb_uid;
}

- (CGRect)wdFrame
{
  return wdFrame(self);
}

- (BOOL)isWDVisible
{
  return self.fb_isVisible;
}

- (BOOL)isWDAccessible
{
  return self.fb_lastSnapshot.isWDAccessible;
}

- (BOOL)isWDAccessibilityContainer
{
  return self.fb_lastSnapshot.isWDAccessibilityContainer;
}

- (BOOL)isWDEnabled
{
  return isWDEnabled(self);
}

- (NSDictionary *)wdRect
{
  return wdRect(self);
}

@end


@implementation XCElementSnapshot (WebDriverAttributes)

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:[FBElementUtils wdAttributeNameForAttributeName:name]];
}

- (NSString *)wdValue
{
  return wdValue(self);
}

- (NSString *)wdName
{
  return wdName(self);
}

- (NSString *)wdLabel
{
  return wdLabel(self);
}

- (NSString *)wdType
{
  return wdType(self);
}

- (NSUInteger)wdUID
{
  return self.fb_uid;
}

- (CGRect)wdFrame
{
  return wdFrame(self);
}

- (BOOL)isWDVisible
{
  return self.fb_isVisible;
}

- (BOOL)isWDAccessible
{
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
    // Snapshots support in iOS 11+ is limited
    return NO;
  }
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
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
    // Snapshots support in iOS 11+ is limited
    return NO;
  }
  for (XCElementSnapshot *child in self.children) {
    if (child.isWDAccessibilityContainer || child.fb_isAccessibilityElement) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isWDEnabled
{
  return isWDEnabled(self);
}

- (NSDictionary *)wdRect
{
  return wdRect(self);
}

@end
