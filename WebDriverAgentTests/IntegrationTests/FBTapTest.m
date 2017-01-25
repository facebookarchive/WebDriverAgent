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

// It is recommnded to verify these tests with different iOS versions

@implementation FBTapTest

- (void)verifyTapWithOrientation:(UIDeviceOrientation)orientation
{
  [self goToAlertsPage];
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:orientation];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  [self.testedApplication.buttons[FBShowAlertButtonName] fb_tapWithError:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

- (void)testTap
{
  [self verifyTapWithOrientation:UIDeviceOrientationPortrait];
}

- (void)testTapInLandscapeLeft
{
  [self verifyTapWithOrientation:UIDeviceOrientationLandscapeLeft];
}

- (void)testTapInLandscapeRight
{
  [self verifyTapWithOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testTapInPortraitUpsideDown
{
  [self verifyTapWithOrientation:UIDeviceOrientationPortraitUpsideDown];
}

- (void)verifyTapByCoordinatesWithOrientation:(UIDeviceOrientation)orientation
{
  [self goToAlertsPage];
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:orientation];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  XCUIElement *dstButton = self.testedApplication.buttons[FBShowAlertButtonName];
  [dstButton fb_tapCoordinate:CGPointMake(dstButton.frame.size.width / 2, dstButton.frame.size.height / 2) error:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

- (void)testTapCoordinates
{
  [self verifyTapByCoordinatesWithOrientation:UIDeviceOrientationPortrait];
}

- (void)testTapCoordinatesInLandscapeLeft
{
  [self verifyTapByCoordinatesWithOrientation:UIDeviceOrientationLandscapeLeft];
}

- (void)testTapCoordinatesInLandscapeRight
{
  [self verifyTapByCoordinatesWithOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testTapCoordinatesInPortraitUpsideDown
{
  [self verifyTapByCoordinatesWithOrientation:UIDeviceOrientationPortraitUpsideDown];
}

@end
