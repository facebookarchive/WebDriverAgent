/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class _XCTestCaseImplementation;

NS_ASSUME_NONNULL_BEGIN

/**
 Class that can be used to proxy existing _XCTestCaseImplementation and
 prevent currently running test from being terminated on any XCTest failure
 */
@interface FBXCTestCaseImplementationFailureHoldingProxy : NSProxy

/**
 Constructor for given existing _XCTestCaseImplementation instance
 */
+ (instancetype)proxyWithXCTestCaseImplementation:(_XCTestCaseImplementation *)internalImplementation;

@end

NS_ASSUME_NONNULL_END
