/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "FBIntegrationTestCase.h"
#import "XCUIDevice+FBRotation.h"

@interface XCUIDeviceRotationTests : FBIntegrationTestCase

@end

@implementation XCUIDeviceRotationTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];
}

- (void)testLandscapeRightOrientation
{
  BOOL success = [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:UIDeviceOrientationLandscapeRight];
  XCTAssertTrue(success, @"Device should support LandscapeRight");
  XCTAssertTrue(self.testedApplication.staticTexts[@"LandscapeLeft"].exists); // Device rotation gives opposite interface rotation
}

- (void)testLandscapeLeftOrientation
{
  BOOL success = [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:UIDeviceOrientationLandscapeLeft];
  XCTAssertTrue(success, @"Device should support LandscapeLeft");
  XCTAssertTrue(self.testedApplication.staticTexts[@"LandscapeRight"].exists); // Device rotation gives opposite interface rotation
}

- (void)testLandscapeRightRotation
{
  BOOL success = [[XCUIDevice sharedDevice] fb_setDeviceRotation:@{
    @"x" : @(0),
    @"y" : @(0),
    @"z" : @(90)
  }];
  XCTAssertTrue(success, @"Device should support LandscapeRight");
  XCTAssertTrue(self.testedApplication.staticTexts[@"LandscapeLeft"].exists); // Device rotation gives opposite interface rotation
}

- (void)testLandscapeLeftRotation
{
  BOOL success = [[XCUIDevice sharedDevice] fb_setDeviceRotation:@{
    @"x" : @(0),
    @"y" : @(0),
    @"z" : @(270)
  }];
  XCTAssertTrue(success, @"Device should support LandscapeLeft");
  XCTAssertTrue(self.testedApplication.staticTexts[@"LandscapeRight"].exists); // Device rotation gives opposite interface rotation
}

- (void)testRotationTiltRotation
{
  UIDeviceOrientation currentRotation = [XCUIDevice sharedDevice].orientation;
  BOOL success = [[XCUIDevice sharedDevice] fb_setDeviceRotation:@{
    @"x" : @(15),
    @"y" : @(0),
    @"z" : @(0)}
  ];
  XCTAssertFalse(success, @"Device should not support tilt");
  XCTAssertEqual(currentRotation, [XCUIDevice sharedDevice].orientation, @"Device doesnt support tilt, should be at previous orientation");
}

@end
