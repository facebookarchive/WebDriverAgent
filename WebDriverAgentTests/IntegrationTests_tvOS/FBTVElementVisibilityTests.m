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
#import "FBTVIntegrationTestCase.h"
#import "FBHomeboardApplication.h"
#import "FBTestMacros.h"
#import "FBXCodeCompatibility.h"
#import "XCUIElement+FBIsVisible.h"

@interface FBTVElementVisibilityTests : FBTVIntegrationTestCase
@end

@implementation FBTVElementVisibilityTests

- (void)testHeadBoardIcons
{
  [self launchApplication];
  [self goToHeadBoardPage];
  
  XCTAssertTrue(self.homeboard.icons[@"IntegrationApp_tvOS"].fb_isVisible);
  XCTAssertTrue(self.homeboard.icons[@"Settings"].fb_isVisible);
}

- (void)testTableViewCells
{
  [self launchApplication];
  [self goToScrollPageWithCells:true];
  XCUIElement *table = self.testedApplication.tables.allElementsBoundByIndex.firstObject;
  for (int i = 0 ; i < 10 ; i++) {
    FBAssertWaitTillBecomesTrue(table.cells.allElementsBoundByIndex[i].fb_isVisible);
    FBAssertWaitTillBecomesTrue(table.staticTexts.allElementsBoundByIndex[i].fb_isVisible);
  }
  for (int i = 30 ; i < 40 ; i++) {
    FBAssertWaitTillBecomesTrue(!table.cells.allElementsBoundByIndex[i].fb_isVisible);
    FBAssertWaitTillBecomesTrue(!table.staticTexts.allElementsBoundByIndex[i].fb_isVisible);
  }
}

@end
