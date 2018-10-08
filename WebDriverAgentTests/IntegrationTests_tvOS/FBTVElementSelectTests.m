/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <WebDriverAgentLib/FBAlert.h>

#import "FBTVIntegrationTestCase.h"
#import "FBTestMacros.h"
#import "XCUIElement+FBTVFocuse.h"

@interface FBTVElementSelectTests : FBTVIntegrationTestCase
@end

@implementation FBTVElementSelectTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToNavigationPage];
  });
}

- (void)showHorizontalLayout
{
  XCUIElement *category = self.testedApplication.cells[@"horizontal_layout"];
  NSError *error;
  XCTAssertTrue([category fb_selectWithError: &error]);
  XCTAssertNil(error);
  XCUIElement * right = self.testedApplication.buttons[@"right"];
  XCUIElement * topLeft = self.testedApplication.buttons[@"top left"];
  FBAssertWaitTillBecomesTrue(right.exists && !topLeft.exists);
}

- (void)showGridLayout
{
  XCUIElement *category = self.testedApplication.cells[@"grid_layout"];
  NSError *error;
  XCTAssertTrue([category fb_selectWithError: &error]);
  XCTAssertNil(error);
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"top left"].exists);
}

- (void)showCustomLayout
{
  XCUIElement *category = self.testedApplication.cells[@"custom_layout"];
  NSError *error;
  XCTAssertTrue([category fb_selectWithError: &error]);
  XCTAssertNil(error);
  XCUIElement * topRight = self.testedApplication.buttons[@"top right"];
  XCUIElement * topLeft = self.testedApplication.buttons[@"top left"];
  FBAssertWaitTillBecomesTrue(topRight.exists && !topLeft.exists);
}

- (void)testVerticalNavigation
{
  XCUIElement *lastElement = self.testedApplication.cells[@"custom_layout"];
  NSError *error;
  XCTAssertTrue([lastElement fb_focuseWithError: &error]);
  XCTAssertNil(error);
  XCTAssertTrue(lastElement.hasFocus);
}

- (void)testErrorNavigation
{
  XCUIElement *disabledElement = self.testedApplication.cells[@"disabled_layout"];
  NSError *error;
  XCTAssertFalse([disabledElement fb_focuseWithError: &error]);
  XCTAssertNotNil(error);
  XCTAssertFalse(disabledElement.hasFocus);
}

- (void)testHorizontalNavigation
{
  [self showHorizontalLayout];
  XCUIElement *rightElement = self.testedApplication.buttons[@"right"];
  NSError *error;
  XCTAssertTrue([rightElement fb_focuseWithError: &error]);
  XCTAssertNil(error);
  XCTAssertTrue(rightElement.hasFocus);
}

- (void)testGridNavigation
{
  [self showGridLayout];
  XCUIElement *rightElement = self.testedApplication.buttons[@"bottom right"];
  NSError *firstNavError;
  XCTAssertTrue([rightElement fb_focuseWithError: &firstNavError]);
  XCTAssertNil(firstNavError);
  XCTAssertTrue(rightElement.hasFocus);
  
  XCUIElement *leftElement = self.testedApplication.cells[@"grid_layout"];
  NSError *secondNavError;
  XCTAssertTrue([leftElement fb_focuseWithError: &secondNavError]);
  XCTAssertNil(secondNavError);
  XCTAssertTrue(leftElement.hasFocus);
}

- (void)testCustomNavigation
{
  [self showCustomLayout];
  XCUIElement *rightElement = self.testedApplication.buttons[@"bottom right"];
  NSError *error;
  XCTAssertTrue([rightElement fb_focuseWithError: &error]);
  XCTAssertNil(error);
  XCTAssertTrue(rightElement.hasFocus);
}

@end
