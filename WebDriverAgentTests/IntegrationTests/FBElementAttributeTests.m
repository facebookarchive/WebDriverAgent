/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBFindElementCommands.h"
#import "XCUIElement+FBAccessibility.h"
#import "XCUIElement+FBIsVisible.h"

@interface FBElementAttributeTests : XCTestCase
@property (nonatomic, strong) XCUIApplication *testedApplication;
@end

@implementation FBElementAttributeTests

- (void)setUp
{
  [super setUp];
  self.testedApplication = [XCUIApplication new];
  [self.testedApplication launch];
  [self.testedApplication.buttons[@"Attributes"] tap];
}

- (void)testIsVisible
{
  XCTAssertTrue(self.testedApplication.buttons[@"Button"].exists);
  XCTAssertTrue(self.testedApplication.buttons[@"Button"].fb_isVisible);

  XCTAssertTrue(self.testedApplication.staticTexts[@"alpha_invisible"].exists);
  XCTAssertFalse(self.testedApplication.staticTexts[@"alpha_invisible"].fb_isVisible);

  XCTAssertTrue(self.testedApplication.staticTexts[@"hidden_invisible"].exists);
  XCTAssertFalse(self.testedApplication.staticTexts[@"hidden_invisible"].fb_isVisible);
}

- (void)testIsAccessible
{
  XCTAssertTrue(self.testedApplication.buttons[@"Button"].exists);
  XCTAssertTrue(self.testedApplication.buttons[@"Button"].fb_isAccessibilityElement);

  XCTAssertTrue(self.testedApplication.buttons[@"not_accessible"].exists);
  XCTAssertFalse(self.testedApplication.buttons[@"not_accessible"].fb_isAccessibilityElement);
}

@end
