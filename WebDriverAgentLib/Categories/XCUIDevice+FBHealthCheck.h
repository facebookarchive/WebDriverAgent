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


@interface XCUIDevice (FBHealthCheck)

/**
 Checks health of XCTest by:
 1) Querying application for some elements,
 2) Triggering some device events.

 !!! Health check might modify simulator state so it should only be called in-between testing sessions

 @param application application used to issue queries
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_healthCheckWithApplication:(nullable XCUIApplication *)application;

@end

NS_ASSUME_NONNULL_END
