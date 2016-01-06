/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

@interface XCUIApplication (SpringBoard)

/**
 * @return SpringBoard application
 */
+ (instancetype)fb_SpringBoard;

/**
 * Taps application on SpringBoard app with given identifer
 * @param identifier identifier of the application to tap
 */
- (void)fb_tapApplicationWithIdentifier:(NSString *)identifier;

@end
