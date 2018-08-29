/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class XCUIApplicationProcess;

NS_ASSUME_NONNULL_BEGIN

/**
 Proxy that would forward all calls to it's applicationProcess.
 However it will block call to waitForQuiescence if shouldWaitForQuiescence is set to NO
 */
@interface FBApplicationProcessProxy : NSProxy

/**
 Convenience initializer
 */
+ (instancetype)proxyWithApplicationProcess:(XCUIApplicationProcess *)applicationProcess;

/**
 It allows to turn on/off waiting for application quiescence, while performing queries. Defaults to NO.
 */
@property (nonatomic, assign) BOOL shouldWaitForQuiescence;

@end

NS_ASSUME_NONNULL_END
