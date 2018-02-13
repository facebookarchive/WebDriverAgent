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
 Forces the device under test to switch to the home screen

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_goToHomescreenWithError:(NSError **)error;

/**
 Checks if the screen is locked or not.
 
 @return YES if screen is locked
 */
- (BOOL)fb_isScreenLocked;

/**
 Forces the device under test to switch to the lock screen. An immediate return will happen if the device is already locked and an error is going to be thrown if the screen has not been locked after the timeout.
 
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_lockScreen:(NSError **)error;

/**
 Forces the device under test to unlock. An immediate return will happen if the device is already unlocked and an error is going to be thrown if the screen has not been unlocked after the timeout.
 
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_unlockScreen:(NSError **)error;

/**
 Returns screenshot
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return Device screenshot as PNG-encoded data or nil in case of failure
 */
- (nullable NSData *)fb_screenshotWithError:(NSError*__autoreleasing*)error;

/**
 Returns device current wifi ip4 address
 */
- (nullable NSString *)fb_wifiIPAddress;

/**
 Opens the particular url scheme using Siri voice recognition helpers.
 This will only work since XCode 8.3/iOS 10.3
 
 @param url The url scheme represented as a string, for example https://apple.com
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation was successful
 */
- (BOOL)fb_openUrl:(NSString *)url error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
