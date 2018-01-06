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

@interface FBKeyboard : NSObject

/**
 Types a string into active element. There must be element with keyboard focus; otherwise an
 error is raised.

 This API discards any modifiers set in the current context by +performWithKeyModifiers:block: so that
 it strictly interprets the provided text. To input keys with modifier flags, use  -typeKey:modifierFlags:.

 @param text that should be typed
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
*/
+ (BOOL)typeText:(NSString *)text error:(NSError **)error;

/**
 Waits until the keyboard is visible on the screen or a timeout happens
 
 @param app that should be typed
 @param timeout the maximum duration in seconds to wait until the keyboard is visible. If the timeout value is equal or less than zero then immediate visibility verification is going to be performed.
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the keyboard is visible after the timeout, otherwise NO.
 */
+ (BOOL)waitUntilVisibleForApplication:(XCUIApplication *)app timeout:(NSTimeInterval)timeout  error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
