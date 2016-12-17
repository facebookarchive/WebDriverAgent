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

@interface XCUIDevice (FBHelpers)

/**
 Matches or mismatches TouchID request

 @param shouldMatch determines if TouchID should be matched
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_fingerTouchShouldMatch:(BOOL)shouldMatch;

/**
 Forces devices to go to homescreen

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_goToHomescreenWithError:(NSError **)error;

/**
 Returns screenshot
 */
- (NSData *)fb_screenshot;

/**
 Returns device current wifi ip4 address
 */
- (nullable NSString *)fb_wifiIPAddress;

@end

NS_ASSUME_NONNULL_END
