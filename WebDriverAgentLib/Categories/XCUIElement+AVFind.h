/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (AVFind)

/**
 Returns an array of descendants matching given xui locator

 @param locator requested xui locator
 @return an array of descendants matching given cell index
 */
- (NSArray<XCUIElement *> *)av_descendantsMatchingXui:(NSString *)locator;

@end

NS_ASSUME_NONNULL_END
