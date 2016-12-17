/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBAccessibility.h"

#import "XCElementSnapshot+FBHelpers.h"
#import "XCTestPrivateSymbols.h"

@implementation XCUIElement (FBAccessibility)

- (BOOL)fb_isAccessibilityElement
{
  if (!self.lastSnapshot) {
    [self resolve];
  }
  return self.lastSnapshot.fb_isAccessibilityElement;
}

@end

@implementation XCElementSnapshot (FBAccessibility)

- (BOOL)fb_isAccessibilityElement
{
  return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsElementAttribute] boolValue];
}

@end
