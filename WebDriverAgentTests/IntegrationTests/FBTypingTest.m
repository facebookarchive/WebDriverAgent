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
#import "XCUIElement+FBTyping.h"

@interface FBTypingTest : FBIntegrationTestCase
@end

@implementation FBTypingTest

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
  NSError *error;
  XCTAssertTrue([textField fb_typeText:text error:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, text);
}

- (void)testTextTypingOnFocusedElement
{
  NSString *text = @"Happy typing";
  XCUIElement *textField = self.testedApplication.textFields[@"aIdentifier"];
  [textField tap];
  XCTAssertTrue(textField.hasKeyboardFocus);
  NSError *error;
  XCTAssertTrue([textField fb_typeText:text error:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, text);
}

- (void)testTextClearing
{
  XCUIElement *textField = self.testedApplication.textFields[@"aIdentifier"];
  [textField tap];
  [textField typeText:@"Happy typing"];
  XCTAssertTrue([textField.value length] > 0);
  NSError *error;
  XCTAssertTrue([textField fb_clearTextWithError:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, @"");
}

@end
