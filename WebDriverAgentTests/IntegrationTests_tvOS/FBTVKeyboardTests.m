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
#import "FBKeyboard.h"
#import "FBRunLoopSpinner.h"

@interface FBTVKeyboardTests : FBTVIntegrationTestCase
@end

@implementation FBTVKeyboardTests

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
  [self select: textField];
  NSError *error;
  XCTAssertTrue([FBKeyboard typeText:text error:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, text);
}

- (void)testTypingWithoutKeyboardPresent
{
  NSError *error;
  XCTAssertFalse([FBKeyboard typeText:@"This should fail" error:&error]);
  XCTAssertNotNil(error);
}

@end
