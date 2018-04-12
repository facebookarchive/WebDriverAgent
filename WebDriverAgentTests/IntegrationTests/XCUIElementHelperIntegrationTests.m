/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import "XCTest/XCUIElementTypes.h"

#import "FBIntegrationTestCase.h"
#import "FBTestMacros.h"
#import "FBElement.h"
#import "FBElementUtils.h"
#import "XCUIElement+FBUtilities.h"

@interface XCUIElementHelperIntegrationTests : FBIntegrationTestCase
@end

@implementation XCUIElementHelperIntegrationTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];
  [self goToAlertsPage];
}

- (void)testObstructionByAlert
{
  XCUIElement *showAlertButton = self.testedApplication.buttons[FBShowAlertButtonName];
  XCTAssertTrue(showAlertButton.exists);
  XCTAssertFalse(showAlertButton.fb_isObstructedByAlert);
  [showAlertButton tap];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
  XCTAssertTrue(showAlertButton.fb_isObstructedByAlert);
}

- (void)testElementObstruction
{
  XCUIElement *showAlertButton = self.testedApplication.buttons[FBShowAlertButtonName];
  XCTAssertTrue(showAlertButton.exists);
  [showAlertButton tap];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);

  XCUIElement *alert = self.testedApplication.alerts.element;
  XCUIElement *acceptAlertButton = self.testedApplication.buttons[@"Will do"];
  XCTAssertTrue(alert.exists);
  XCTAssertTrue(acceptAlertButton.exists);

  XCTAssertTrue([alert fb_obstructsElement:showAlertButton]);
  XCTAssertFalse([alert fb_obstructsElement:acceptAlertButton]);
}

- (void)testDescendantsFiltering
{
  NSArray<XCUIElement *> *buttons = self.testedApplication.buttons.allElementsBoundByAccessibilityElement;
  XCTAssertTrue(buttons.count > 0);
  NSArray<XCUIElement *> *windows = self.testedApplication.windows.allElementsBoundByAccessibilityElement;
  XCTAssertTrue(windows.count > 0);
  
  NSMutableArray<XCUIElement *> *allElements = [NSMutableArray array];
  [allElements addObjectsFromArray:buttons];
  [allElements addObjectsFromArray:windows];
  
  NSMutableArray<XCElementSnapshot *> *buttonSnapshots = [NSMutableArray array];
  [buttonSnapshots addObject:[buttons.firstObject fb_lastSnapshot]];
  
  NSArray<XCUIElement *> *result = [self.testedApplication fb_filterDescendantsWithSnapshots:buttonSnapshots];
  XCTAssertEqual(1, result.count);
  XCTAssertEqual([result.firstObject elementType], XCUIElementTypeButton);
}

@end
