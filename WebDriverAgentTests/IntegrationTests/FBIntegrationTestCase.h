/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

/**
 XCTestCase helper class used for integration tests
 */
@interface FBIntegrationTestCase : XCTestCase
@property (nonatomic, strong, readonly) XCUIApplication *testedApplication;

/**
 Navigates integration app to attributes page
 */
- (void)goToAttributesPage;

/**
 Navigates to SpringBoard
 */
- (void)goToSpringBoard;

@end
