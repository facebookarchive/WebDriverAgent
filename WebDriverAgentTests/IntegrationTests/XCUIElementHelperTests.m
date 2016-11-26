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
#import "XCUIElement+FBUtilities.h"
#import "FBElementUtils.h"

@interface XCUIElementHelperTests : FBIntegrationTestCase
@end

@implementation XCUIElementHelperTests

- (void)setUp
{
  [super setUp];
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

- (void)testDescendantsCategorizationByType
{
  NSArray *buttons = [self.testedApplication.buttons allElementsBoundByIndex];
  NSArray *sameButtons = [self.testedApplication.buttons allElementsBoundByIndex];
  NSArray *windows = [self.testedApplication.windows allElementsBoundByIndex];
  
  NSMutableArray *allElements = [NSMutableArray array];
  [allElements addObjectsFromArray:buttons];
  [allElements addObjectsFromArray:sameButtons];
  [allElements addObjectsFromArray:windows];
  
  NSSet *byTypes = [FBElementUtils fb_getUniqueElementsTypes:allElements];
  NSDictionary *categorizedDescendants = [self.testedApplication fb_categorizeDescendants:byTypes];
  XCTAssertEqual(2, [categorizedDescendants count]);
  XCTAssertEqual([categorizedDescendants[@(XCUIElementTypeButton)] count], [buttons count]);
  XCTAssertEqual([categorizedDescendants[@(XCUIElementTypeWindow)] count], [windows count]);
}

@end
