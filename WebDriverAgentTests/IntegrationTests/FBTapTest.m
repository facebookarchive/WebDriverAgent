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
#import "XCUIElement+FBTap.h"

@interface FBTapTest : FBIntegrationTestCase
@end

@implementation FBTapTest

- (void)testTap
{
  [self goToAlertsPage];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  [self.testedApplication.buttons[FBShowAlertButtonName] fb_tapWithError:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

@end
