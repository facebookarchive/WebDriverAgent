/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCElementSnapshot.h>

extern NSNumber *FB_XCAXAIsVisibleAttribute;
extern NSNumber *FB_XCAXAIsElementAttribute;

@interface XCElementSnapshot (Helpers)

+ (XCElementSnapshot *)fb_snapshotForAccessibilityElement:(XCAccessibilityElement *)accessibilityElement;

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type;

- (XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type;

- (id)fb_attributeValue:(NSNumber *)attribute;

@end
