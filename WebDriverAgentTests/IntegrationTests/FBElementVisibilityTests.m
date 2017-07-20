/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBApplication.h"
#import "FBIntegrationTestCase.h"
#import "FBSpringboardApplication.h"
#import "FBTestMacros.h"
#import "XCUIElement+FBIsVisible.h"

@interface FBElementVisibilityTests : FBIntegrationTestCase
@end

@implementation FBElementVisibilityTests

- (void)testSpringBoardIcons
{
  [self launchApplication];
  [self goToSpringBoardFirstPage];

  // Check Icons on first screen
  XCTAssertTrue(self.springboard.icons[@"Calendar"].fb_isVisible);
  XCTAssertTrue(self.springboard.icons[@"Reminders"].fb_isVisible);

  // Check Icons on second screen screen
  XCTAssertFalse(self.springboard.icons[@"IntegrationApp"].fb_isVisible);
}

- (void)testSpringBoardSubfolder
{
  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    return;
  }
  [self launchApplication];
  [self goToSpringBoardExtras];
  XCTAssertFalse(self.springboard.icons[@"Extras"].otherElements[@"Contacts"].fb_isVisible);
}

- (void)testExtrasIconContent
{
  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    return;
  }
  [self launchApplication];
  [self goToSpringBoardExtras];
  [self.springboard.icons[@"Extras"] tap];
  FBAssertWaitTillBecomesTrue(self.springboard.icons[@"Contacts"].fb_isVisible);
  NSArray *elements = self.springboard.pageIndicators.allElementsBoundByIndex;
  for (XCUIElement *element in elements) {
    XCTAssertFalse(element.fb_isVisible);
  }
}

- (void)testIconsFromSearchDashboard
{
  [self launchApplication];
  [self goToSpringBoardDashboard];
  XCTAssertFalse(self.springboard.icons[@"Reminders"].fb_isVisible);
  XCTAssertFalse(self.springboard.icons[@"IntegrationApp"].fb_isVisible);
}

- (void)testTableViewCells
{
  [self launchApplication];
  [self goToScrollPageWithCells:YES];
  for (int i = 0 ; i < 10 ; i++) {
    XCTAssertTrue(self.testedApplication.cells.allElementsBoundByIndex[i].fb_isVisible);
    XCTAssertTrue(self.testedApplication.staticTexts.allElementsBoundByIndex[i].fb_isVisible);
  }
  for (int i = 30 ; i < 40 ; i++) {
    XCTAssertFalse(self.testedApplication.cells.allElementsBoundByIndex[i].fb_isVisible);
    XCTAssertFalse(self.testedApplication.staticTexts.allElementsBoundByIndex[i].fb_isVisible);
  }
}

@end
