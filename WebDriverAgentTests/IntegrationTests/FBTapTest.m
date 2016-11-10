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

#import "FBElementCache.h"
#import "FBTestMacros.h"
#import "XCUIDevice+FBRotation.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBIsVisible.h"

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

- (void)testTapInLandscapeLeft
{
  [self goToAlertsPage];
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:UIDeviceOrientationLandscapeLeft];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  [self.testedApplication.buttons[FBShowAlertButtonName] fb_tapWithError:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

- (void)testTapInLandscapeRight
{
  [self goToAlertsPage];
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:UIDeviceOrientationLandscapeRight];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  [self.testedApplication.buttons[FBShowAlertButtonName] fb_tapWithError:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

- (void)testTapInPortraitUpsideDown
{
  [self goToAlertsPage];
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:UIDeviceOrientationPortraitUpsideDown];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  [self.testedApplication.buttons[FBShowAlertButtonName] fb_tapWithError:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

@end
