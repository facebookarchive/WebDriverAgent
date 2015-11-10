/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBIsVisible.h"

#import "XCAXClient_iOS.h"
#import "XCUIElement.h"

extern const NSString *const XC_kAXXCAttributeIsVisible;
NSArray *XCAXAccessibilityAttributesForStringAttributes(NSArray *list);

@implementation XCUIElement (FBIsVisible)

- (BOOL)isFBVisible
{
  return self.lastSnapshot.isFBVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

static NSNumber *FB_XCAXAIsVisibileAttribute;

+ (void)load
{
  FB_XCAXAIsVisibileAttribute = (NSNumber *)[XCAXAccessibilityAttributesForStringAttributes(@[XC_kAXXCAttributeIsVisible]) lastObject];
}

- (BOOL)isFBVisible
{
  NSDictionary *attributesResult = [[XCAXClient_iOS sharedClient] attributesForElementSnapshot:self attributeList:@[FB_XCAXAIsVisibileAttribute]];
  return [attributesResult[FB_XCAXAIsVisibileAttribute] boolValue];
}

@end
