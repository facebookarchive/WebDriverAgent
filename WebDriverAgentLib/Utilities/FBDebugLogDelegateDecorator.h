/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <WebDriverAgentLib/XCDebugLogDelegate-Protocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 XCTestLogger decorator that will print all debug information to console
 */
@interface FBDebugLogDelegateDecorator : NSObject <XCDebugLogDelegate>

/**
 Decorates XCTestLogger by also printing debug message to console
 */
+ (void)decorateXCTestLogger;

@end

NS_ASSUME_NONNULL_END
