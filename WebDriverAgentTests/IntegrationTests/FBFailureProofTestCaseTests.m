/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBFailureProofTestCase.h"
#import "FBExceptionHandler.h"

@interface FBFailureProofTestCaseTests : FBFailureProofTestCase
@end

@implementation FBFailureProofTestCaseTests

- (void)setUp
{
  [super setUp];
  [[XCUIApplication new] launch];
}

- (void)testPreventElementSearchFailure
{
  [[XCUIApplication new].buttons[@"kaboom"] tap];
}

- (void)testInactiveAppSearch
{
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  [[XCUIApplication new].buttons[@"kaboom"] tap];
}

- (void)testPreventAssertFailure
{
  XCTAssertNotNil(nil);
}

@end
