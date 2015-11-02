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

#import "XCUIElement+UIAClassMapping.h"
#import "XCUIElement.h"

#define FBTransferEmptyStringToNil(value) ([value isEqual:@""] ? nil : value)
#define FBFirstNonEmptyValue(value1, value2) ([value1 isEqual:@""] ? value2 : value1)

@implementation XCUIElement (WebDriverAttributesForwarding)

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  struct objc_method_description descr = protocol_getMethodDescription(@protocol(WebDriverAttributes), aSelector, YES, YES);
  BOOL isWebDriverAttributesSelector = descr.name != nil;
  if(isWebDriverAttributesSelector) {
      return self.lastSnapshot;
  }
  return nil;
}

@end


@implementation XCElementSnapshot (WebDriverAttributes)

- (id)valueForWDAttributeName:(NSString *)name
{
  return [self valueForKey:xctAttributeNameForWDAttributeName(name)];
}

- (id)wdValue
{
  id value = self.value;
  if (self.elementType == XCUIElementTypeStaticText) {
    value = FBFirstNonEmptyValue(self.value, self.label);
  }
  return FBTransferEmptyStringToNil(value);
}

- (NSString *)wdName
{
  return FBTransferEmptyStringToNil(FBFirstNonEmptyValue(self.identifier, self.label));
}

- (NSString *)wdLabel
{
  return FBTransferEmptyStringToNil(self.label);
}

- (NSString *)wdType
{
  return [XCUIElement UIAClassNameWithElementType:self.elementType];
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

@end


NSString *xctAttributeNameForWDAttributeName(NSString *wdName)
{
  return [NSString stringWithFormat:@"wd%@", wdName.capitalizedString];
}
