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


@implementation XCElementSnapshot (WebDriverAttributes)

static NSMutableDictionary<NSNumber *, NSMutableDictionary<NSString *, NSMutableDictionary<NSString*, id> *> *> *fb_wdAttributesCache;

+ (void)load
{
  fb_wdAttributesCache = [NSMutableDictionary dictionary];
}

- (id)fb_cachedValueWithAttributeName:(NSString *)name valueGetter:(id (^)(void))valueGetter
{
  NSNumber *generation = [NSNumber numberWithUnsignedLongLong:self.generation];
  NSMutableDictionary<NSString *, NSMutableDictionary<NSString*, id> *> *cachedSnapshotsForGeneration = [fb_wdAttributesCache objectForKey:generation];
  if (nil == cachedSnapshotsForGeneration) {
    [fb_wdAttributesCache removeAllObjects];
    cachedSnapshotsForGeneration = [NSMutableDictionary dictionary];
    [fb_wdAttributesCache setObject:cachedSnapshotsForGeneration forKey:generation];
  }
  NSString *selfId = [NSString stringWithFormat:@"%p", (void *)self];
  NSMutableDictionary<NSString*, id> *snapshotAttributes = [cachedSnapshotsForGeneration objectForKey:selfId];
  if (nil == snapshotAttributes) {
    snapshotAttributes = [NSMutableDictionary dictionary];
    [cachedSnapshotsForGeneration setObject:snapshotAttributes forKey:selfId];
  }
  id cachedValue = [snapshotAttributes objectForKey:name];
  if (nil != cachedValue) {
    return cachedValue == [NSNull null] ? nil : cachedValue;
  }
  
  id computedValue = valueGetter();
  [snapshotAttributes setObject:(nil == computedValue ? [NSNull null] : computedValue) forKey:name];
  return computedValue;
}

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:[FBElementUtils wdAttributeNameForAttributeName:name]];
}

- (NSString *)wdValue
{
  id (^getter)(void) = ^id(void) {
    id value = self.value;
    XCUIElementType elementType = self.elementType;
    if (elementType == XCUIElementTypeStaticText) {
      NSString *label = self.label;
      value = FBFirstNonEmptyValue(value, label);
    } else if (elementType == XCUIElementTypeButton) {
      NSNumber *isSelected = self.isSelected ? @YES : nil;
      value = FBFirstNonEmptyValue(value, isSelected);
    } else if (elementType == XCUIElementTypeSwitch) {
      value = @([value boolValue]);
    } else if (elementType == XCUIElementTypeTextView ||
               elementType == XCUIElementTypeTextField ||
               elementType == XCUIElementTypeSecureTextField) {
      NSString *placeholderValue = self.placeholderValue;
      value = FBFirstNonEmptyValue(value, placeholderValue);
    }
    value = FBTransferEmptyStringToNil(value);
    if (value) {
      value = [NSString stringWithFormat:@"%@", value];
    }
    return value;
  };
  
  return [self fb_cachedValueWithAttributeName:@"wdValue" valueGetter:getter];
}

- (NSString *)wdName
{
  id (^getter)(void) = ^id(void) {
    NSString *identifier = self.identifier;
    if (nil != identifier && identifier.length != 0) {
      return identifier;
    }
    NSString *label = self.label;
    return FBTransferEmptyStringToNil(label);
  };
  
  return [self fb_cachedValueWithAttributeName:@"wdName" valueGetter:getter];
}

- (NSString *)wdLabel
{
  id (^getter)(void) = ^id(void) {
    NSString *label = self.label;
    if (self.elementType == XCUIElementTypeTextField) {
      return label;
    }
    return FBTransferEmptyStringToNil(label);
  };
  
  return [self fb_cachedValueWithAttributeName:@"wdLabel" valueGetter:getter];
}

- (NSString *)wdType
{
  id (^getter)(void) = ^id(void) {
    return [FBElementTypeTransformer stringWithElementType:self.elementType];
  };
  
  return [self fb_cachedValueWithAttributeName:@"wdType" valueGetter:getter];
}

- (NSString *)wdUID
{
  id (^getter)(void) = ^id(void) {
    return self.fb_uid;
  };
  
  return [self fb_cachedValueWithAttributeName:@"wdUID" valueGetter:getter];
}

- (CGRect)wdFrame
{
  id (^getter)(void) = ^id(void) {
    return [NSValue valueWithCGRect:CGRectIntegral(self.frame)];
  };
  
  return [[self fb_cachedValueWithAttributeName:@"wdFrame" valueGetter:getter] CGRectValue];
}

- (BOOL)isWDVisible
{
  id (^getter)(void) = ^id(void) {
    return @(self.fb_isVisible);
  };
  
  return [[self fb_cachedValueWithAttributeName:@"isWDVisible" valueGetter:getter] boolValue];
}

- (BOOL)isWDAccessible
{
  id (^getter)(void) = ^id(void) {
    XCUIElementType elementType = self.elementType;
    // Special cases:
    // Table view cell: we consider it accessible if it's container is accessible
    // Text fields: actual accessible element isn't text field itself, but nested element
    if (elementType == XCUIElementTypeCell) {
      if (!self.fb_isAccessibilityElement) {
        XCElementSnapshot *containerView = [[self children] firstObject];
        if (!containerView.fb_isAccessibilityElement) {
          return @NO;
        }
      }
    } else if (elementType != XCUIElementTypeTextField && elementType != XCUIElementTypeSecureTextField) {
      if (!self.fb_isAccessibilityElement) {
        return @NO;
      }
    }
    XCElementSnapshot *parentSnapshot = self.parent;
    while (parentSnapshot) {
      // In the scenario when table provides Search results controller, table could be marked as accessible element, even though it isn't
      // As it is highly unlikely that table view should ever be an accessibility element itself,
      // for now we work around that by skipping Table View in container checks
      if (parentSnapshot.fb_isAccessibilityElement && parentSnapshot.elementType != XCUIElementTypeTable) {
        return @NO;
      }
      parentSnapshot = parentSnapshot.parent;
    }
    return @YES;
  };
  
  return [[self fb_cachedValueWithAttributeName:@"isWDAccessible" valueGetter:getter] boolValue];
}

- (BOOL)isWDAccessibilityContainer
{
  id (^getter)(void) = ^id(void) {
    NSArray<XCElementSnapshot *> *children = self.children;
    for (XCElementSnapshot *child in children) {
      if (child.isWDAccessibilityContainer || child.fb_isAccessibilityElement) {
        return @YES;
      }
    }
    return @NO;
  };
  
  return [[self fb_cachedValueWithAttributeName:@"isWDAccessibilityContainer" valueGetter:getter] boolValue];
}

- (BOOL)isWDEnabled
{
  id (^getter)(void) = ^id(void) {
    return @(self.isEnabled);
  };
  
  return [[self fb_cachedValueWithAttributeName:@"isWDEnabled" valueGetter:getter] boolValue];
}

- (NSDictionary *)wdRect
{
  id (^getter)(void) = ^id(void) {
    CGRect frame = self.wdFrame;
    return @{
      @"x": @(CGRectGetMinX(frame)),
      @"y": @(CGRectGetMinY(frame)),
      @"width": @(CGRectGetWidth(frame)),
      @"height": @(CGRectGetHeight(frame)),
    };
  };
  
  return [self fb_cachedValueWithAttributeName:@"wdRect" valueGetter:getter];
}

@end
