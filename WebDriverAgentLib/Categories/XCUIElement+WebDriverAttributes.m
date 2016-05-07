/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+WebDriverAttributes.h"

#import <objc/runtime.h>

#import "FBElementTypeTransformer.h"
#import "XCUIElement+FBAccessibility.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement.h"

#define FBTransferEmptyStringToNil(value) ([value isEqual:@""] ? nil : value)
#define FBFirstNonEmptyValue(value1, value2) ([value1 isEqual:@""] ? value2 : value1)

@implementation XCUIElement (WebDriverAttributesForwarding)

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  struct objc_method_description descr = protocol_getMethodDescription(@protocol(FBElement), aSelector, YES, YES);
  BOOL isWebDriverAttributesSelector = descr.name != nil;
  if(!isWebDriverAttributesSelector) {
    return nil;
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

- (id)valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:wdAttributeNameForAttributeName(name)];
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
  return self.frame;
}

- (BOOL)isWDVisible
{
  return self.isFBVisible;
}

- (BOOL)isWDAccessible
{
  if (!self.isFbAccessibilityElement) {
    return NO;
  }
  XCElementSnapshot *parentSnapshot = self.parent;
  while (parentSnapshot) {
    if (parentSnapshot.isFbAccessibilityElement) {
      return NO;
    }
    parentSnapshot = parentSnapshot.parent;
  }
  return YES;
}

- (BOOL)isWDEnabled
{
  return self.isEnabled;
}

- (NSDictionary *)wdRect
{
  return
  @{
    @"origin":
      @{
        @"x": @(CGRectGetMinX(self.frame)),
        @"y": @(CGRectGetMinY(self.frame)),
        },
    @"size":
      @{
        @"width": @(CGRectGetWidth(self.frame)),
        @"height": @(CGRectGetHeight(self.frame)),
        },
    };
}

- (NSDictionary *)wdSize
{
    return self.wdRect[@"size"];
}

- (NSDictionary *)wdLocation
{
    return self.wdRect[@"origin"];
}

@end
