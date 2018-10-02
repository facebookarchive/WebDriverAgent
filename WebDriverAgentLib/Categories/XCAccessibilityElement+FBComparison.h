/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import "XCAccessibilityElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCAccessibilityElement (FBComparison)

/**
 Compares two XCAccessibilityElement instances
 
 @param other the other element instance
 @return YES if both elements are equal
 */
- (BOOL)isEqualToElement:(nullable XCAccessibilityElement *)other;

@end

NS_ASSUME_NONNULL_END
