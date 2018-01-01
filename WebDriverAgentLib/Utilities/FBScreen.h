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

@interface FBScreen : NSObject

/**
 The scale factor of the main device's screen
 */
+ (double)scale;

/**
 The absolute size of application's status bar or CGSizeZero if it's hidden or does not exist
 */
+ (CGSize)statusBarSizeForApplication:(XCUIApplication *)application;

@end

NS_ASSUME_NONNULL_END
