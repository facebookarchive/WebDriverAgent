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

  // If lastSnapshot is still missing aplication is probably not active. Returning empty element instead of crashing.
  // This will work well, if element search is requested (will not match anything) and reqesting properties values (will return nils).
  return self.fb_lastSnapshot ?: [XCElementSnapshot new];
}

@end

static char const * const FBCachedAttributesKey = "FBCachedAttributes";

@implementation XCElementSnapshot (WebDriverAttributes)

@dynamic fb_cachedAttributes;

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:[FBElementUtils wdAttributeNameForAttributeName:name]];
}

- (NSMutableDictionary<NSString *, id> *)fb_cachedAttributes
{
  return (NSMutableDictionary<NSString *, id> *)objc_getAssociatedObject(self, FBCachedAttributesKey);
}

- (void)setFb_cachedAttributes:(NSMutableDictionary<NSString *, id> *)newCachedAttributes
{
  objc_setAssociatedObject(self, FBCachedAttributesKey, newCachedAttributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)fb_cachedValueFor:(NSString *)attributeName valueGetter:(id (^)(void))valueGetter
{
  if (nil == self.fb_cachedAttributes) {
    [self setFb_cachedAttributes:[NSMutableDictionary new]];
  }
  id result = [self.fb_cachedAttributes objectForKey:attributeName];
  if (nil != result) {
    if ([NSNull null] == result) {
      return nil;
    }
    return result;
  }
  return valueGetter();
}

- (void)fb_setCachedValue:(id)value forAttributeName:(NSString *)name
{
  [self.fb_cachedAttributes setObject:nil == value ? [NSNull null] : value forKey:name];
}

- (NSString *)wdValue
{
  id (^valueGetter)(void) = ^id(void) {
    id value = self.value;
    NSUInteger elementType = self.elementType;
    if (elementType == XCUIElementTypeStaticText) {
      NSString *label = self.label;
      value = FBFirstNonEmptyValue(value, label);
    }
    if (elementType == XCUIElementTypeButton) {
      BOOL isSelected = self.isSelected;
      value = FBFirstNonEmptyValue(value, (isSelected ? @YES : nil));
    }
    if (elementType == XCUIElementTypeSwitch) {
      value = @([value boolValue]);
    }
    if (elementType == XCUIElementTypeTextView ||
        elementType == XCUIElementTypeTextField ||
        elementType == XCUIElementTypeSecureTextField) {
      NSString *placeholderValue = self.placeholderValue;
      value = FBFirstNonEmptyValue(value, placeholderValue);
    }
    value = FBTransferEmptyStringToNil(value);
    if (nil != value) {
      value = [NSString stringWithFormat:@"%@", value];
    }
    return value;
  };
  return [self fb_cachedValueFor:@"wdValue" valueGetter:valueGetter];
}

- (NSString *)wdName
{
  id (^valueGetter)(void) = ^id(void) {
    NSString *identifier = self.identifier;
    NSString *label = self.label;
    return FBTransferEmptyStringToNil(FBFirstNonEmptyValue(identifier, label));
  };
  return [self fb_cachedValueFor:@"wdName" valueGetter:valueGetter];
}

- (NSString *)wdLabel
{
  id (^valueGetter)(void) = ^id(void) {
    NSString *label = self.label;
    if (self.elementType == XCUIElementTypeTextField) {
      return label;
    }
    return FBTransferEmptyStringToNil(label);
  };
  return [self fb_cachedValueFor:@"wdLabel" valueGetter:valueGetter];
}

- (NSString *)wdType
{
  id (^valueGetter)(void) = ^id(void) {
    return [FBElementTypeTransformer stringWithElementType:self.elementType];
  };
  return [self fb_cachedValueFor:@"wdType" valueGetter:valueGetter];
}

- (NSUInteger)wdUID
{
  id (^valueGetter)(void) = ^id(void) {
    return @(self.fb_uid);
  };
  return [[self fb_cachedValueFor:@"wdUID" valueGetter:valueGetter] integerValue];
}

- (CGRect)wdFrame
{
  id (^valueGetter)(void) = ^id(void) {
    return @(CGRectIntegral(self.frame));
  };
  return [[self fb_cachedValueFor:@"wdFrame" valueGetter:valueGetter] CGRectValue];
}

- (BOOL)isWDVisible
{
  id (^valueGetter)(void) = ^id(void) {
    return @(self.fb_isVisible);
  };
  return [[self fb_cachedValueFor:@"isWDVisible" valueGetter:valueGetter] boolValue];
}

- (BOOL)isWDAccessible
{
  id (^valueGetter)(void) = ^id(void) {
    // Special cases:
    // Table view cell: we consider it accessible if it's container is accessible
    // Text fields: actual accessible element isn't text field itself, but nested element
    if (self.elementType == XCUIElementTypeCell) {
      if (!self.fb_isAccessibilityElement) {
        XCElementSnapshot *containerView = [[self children] firstObject];
        if (!containerView.fb_isAccessibilityElement) {
          return @(NO);
        }
      }
    } else if (self.elementType != XCUIElementTypeTextField && self.elementType != XCUIElementTypeSecureTextField) {
      if (!self.fb_isAccessibilityElement) {
        return @(NO);
      }
    }
    XCElementSnapshot *parentSnapshot = self.parent;
    while (parentSnapshot) {
      // In the scenario when table provides Search results controller, table could be marked as accessible element, even though it isn't
      // As it is highly unlikely that table view should ever be an accessibility element itself,
      // for now we work around that by skipping Table View in container checks
      if (parentSnapshot.fb_isAccessibilityElement && parentSnapshot.elementType != XCUIElementTypeTable) {
        return @(NO);
      }
      parentSnapshot = parentSnapshot.parent;
    }
    return @(YES);
  };
  return [[self fb_cachedValueFor:@"isWDAccessible" valueGetter:valueGetter] boolValue];
}

- (BOOL)isWDAccessibilityContainer
{
  id (^valueGetter)(void) = ^id(void) {
    for (XCElementSnapshot *child in self.children) {
      if (child.isWDAccessibilityContainer || child.fb_isAccessibilityElement) {
        return @(YES);
      }
    }
    return @(NO);
  };
  return [[self fb_cachedValueFor:@"isWDAccessibilityContainer" valueGetter:valueGetter] boolValue];
}

- (BOOL)isWDEnabled
{
  id (^valueGetter)(void) = ^id(void) {
    return @(self.isEnabled);
  };
  return [[self fb_cachedValueFor:@"isWDEnabled" valueGetter:valueGetter] boolValue];
}

- (NSDictionary *)wdRect
{
  id (^valueGetter)(void) = ^id(void) {
    CGRect frame = self.wdFrame;
    return @{
             @"x": @(CGRectGetMinX(frame)),
             @"y": @(CGRectGetMinY(frame)),
             @"width": @(CGRectGetWidth(frame)),
             @"height": @(CGRectGetHeight(frame)),
             };
  };
  return [self fb_cachedValueFor:@"wdRect" valueGetter:valueGetter];
}

@end
