/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBTVIntegrationTestCase.h"
#import "FBExceptionHandler.h"
#import "XCUIElement+FBTVFocuse.h"

@interface FBTVSearchFailureTests : FBTVIntegrationTestCase
@end

@implementation FBTVSearchFailureTests

- (void)setUp
{
  [super setUp];
  [[XCUIApplication new] launch];
}

- (void)testPreventElementSearchFailure
{
  NSError *error;
  [[XCUIApplication new].buttons[@"kaboom"] fb_selectWithError:&error];
  XCTAssertNotNil(error);
}

- (void)testInactiveAppSearch
{
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  NSError *error;
  [[XCUIApplication new].buttons[@"kaboom"] fb_selectWithError:&error];
  XCTAssertNotNil(error);
}


@end
