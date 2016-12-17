/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

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

@end

NS_ASSUME_NONNULL_END
