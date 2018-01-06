/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBIntegrationTestCase.h"
#import "FBKeyboard.h"
#import "FBRunLoopSpinner.h"

@interface FBKeyboardTests : FBIntegrationTestCase
@end

@implementation FBKeyboardTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];
  [self goToAttributesPage];
}

- (void)testTextTyping
{
  NSString *text = @"Happy typing";
  XCUIElement *textField = self.testedApplication.textFields[@"aIdentifier"];
  [textField tap];
  NSError *error;
  XCTAssertTrue([FBKeyboard waitUntilVisibleForApplication:self.testedApplication timeout:1 error:&error]);
  XCTAssertNil(error);
  XCTAssertTrue([FBKeyboard typeText:text error:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, text);
}

- (void)testKeyboardPresenceVerification
{
  NSError *error;
  XCTAssertFalse([FBKeyboard waitUntilVisibleForApplication:self.testedApplication timeout:1 error:&error]);
  XCTAssertNotNil(error);
}

@end
