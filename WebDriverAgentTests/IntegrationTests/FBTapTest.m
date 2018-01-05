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

#import "FBAlert.h"
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
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:orientation];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  [self.testedApplication.buttons[FBShowAlertButtonName] fb_tapWithError:&error];
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToAlertsPage];
  });
}

- (void)tearDown
{
  [super tearDown];
  [[FBAlert alertWithApplication:self.testedApplication] dismissWithError:nil];
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

// Visibility detection for upside-down orientation is broken
// and cannot be workarounded properly, but this is not very important for Appium, since
// We don't support such orientation anyway
- (void)disabled_testTapInPortraitUpsideDown
{
  [self verifyTapWithOrientation:UIDeviceOrientationPortraitUpsideDown];
}

- (void)verifyTapByCoordinatesWithOrientation:(UIDeviceOrientation)orientation
{
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

// Visibility detection for upside-down orientation is broken
// and cannot be workarounded properly, but this is not very important for Appium, since
// We don't support such orientation anyway
- (void)disabled_testTapCoordinatesInPortraitUpsideDown
{
  [self verifyTapByCoordinatesWithOrientation:UIDeviceOrientationPortraitUpsideDown];
}

@end
