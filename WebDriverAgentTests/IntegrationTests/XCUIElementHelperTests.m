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
#import "FBTestMacros.h"
#import "XCUIElement+Utilities.h"

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

@end
