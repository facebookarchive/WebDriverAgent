/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCUIElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBTyping)

/**
 Types a text into element.
 It will try to activate keyboard on element, if element has no keyboard focus.

 @param text text that should be typed
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_typeText:(NSString *)text error:(NSError **)error;

/**
 Types a text into element.
 It will try to activate keyboard on element, if element has no keyboard focus.

 @param text text that should be typed
 @param frequency Frequency of typing (letters per sec)
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_typeText:(NSString *)text frequency:(NSUInteger)frequency error:(NSError **)error;

/**
 Clears text on element.
 It will try to activate keyboard on element, if element has no keyboard focus.

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_clearTextWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
