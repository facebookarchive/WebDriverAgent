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
#import "XCUIElement+FBTyping.h"

@interface FBTVTypingTest : FBTVIntegrationTestCase
@end

@implementation FBTVTypingTest

- (void)setUp
{
  [super setUp];
  [self launchApplication];
  [self goToAttributesPage];
}

- (void)testTextTyping
{
  NSString *text = @"Cannot automatically open keyboard";
  XCUIElement *textField = self.testedApplication.textFields[@"aIdentifier"];
  NSError *error;
  XCTAssertFalse([textField fb_typeText:text error:&error]);
  XCTAssertNotNil(error);
}

- (void)testTextTypingOnFocusedElement
{
  NSString *text = @"Happy typing";
  XCUIElement *textField = self.testedApplication.textFields[@"aIdentifier"];
  [self select:textField];
  XCTAssertTrue(textField.hasKeyboardFocus);
  NSError *error;
  XCTAssertTrue([textField fb_typeText:text error:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, text);
}

- (void)testTextClearing
{
  XCUIElement *textField = self.testedApplication.textFields[@"aIdentifier"];
  [self select:textField];
  [textField typeText:@"Happy typing"];
  XCTAssertTrue([textField.value length] > 0);
  NSError *error;
  XCTAssertTrue([textField fb_clearTextWithError:&error]);
  XCTAssertNil(error);
  XCTAssertEqualObjects(textField.value, @"Hold ￼ to dictate");
}

@end
