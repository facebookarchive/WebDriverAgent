//
//  XCUIDeviceRotTests.m
//  WebDriverAgent
//
//  Created by Rafael Chavez on 7/22/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FBIntegrationTestCase.h"
#import "XCUIDevice+FBRotation.h"

@interface XCUIDeviceRotationTests : FBIntegrationTestCase

@end

@implementation XCUIDeviceRotationTests


- (void)setUp
{
    [super setUp];
    //setup portrait before any test
    [[XCUIDevice sharedDevice] setDeviceRotation:@{@"x" : @(0),
                                                   @"y" : @(0),
                                                   @"z" : @(0)}];
}

- (void)testLandscapeRightRotation
{
    BOOL success = [[XCUIDevice sharedDevice] setDeviceRotation:@{@"x" : @(0),
                                                                  @"y" : @(0),
                                                                  @"z" : @(90)}];
    XCTAssertTrue(success, @"Device should support LandscapeRight");
    XCTAssertEqual(UIDeviceOrientationLandscapeRight, [XCUIDevice sharedDevice].orientation, @"Device should be in landscape left mode");
}

- (void)testLandscapeLeftRotation
{
    BOOL success = [[XCUIDevice sharedDevice] setDeviceRotation:@{@"x" : @(0),
                                                                  @"y" : @(0),
                                                                  @"z" : @(270)}];
    XCTAssertTrue(success, @"Device should support LandscapeLeft");
    XCTAssertEqual(UIDeviceOrientationLandscapeLeft, [XCUIDevice sharedDevice].orientation, @"Device should be in landscape right mode");
}

- (void)testRotationTiltRotation
{
    UIDeviceOrientation currentRotation = [XCUIDevice sharedDevice].orientation;
    BOOL success = [[XCUIDevice sharedDevice] setDeviceRotation:@{@"x" : @(15),
                                                                  @"y" : @(0),
                                                                  @"z" : @(0)}];
    XCTAssertFalse(success, @"Device should not support tilt");
    XCTAssertEqual(currentRotation, [XCUIDevice sharedDevice].orientation, @"Device doesnt support tilt, should be at previous orientation");
}


@end
