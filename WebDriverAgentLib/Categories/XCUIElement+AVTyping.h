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

@interface XCUIElement (AVTyping)

/**
 Types a text into element with pauses.
 It will try to activate keyboard on element, if element has no keyboard focus.

 @param text text that should be typed
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)av_slowTypeText:(NSString *)text error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
