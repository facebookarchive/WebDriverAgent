/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBApplication.h"
#import "FBTVIntegrationTestCase.h"
#import "FBTestMacros.h"
#import "FBHomeboardApplication.h"
#import "XCUIApplication+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"

@interface TVXCUIApplicationHelperTests : FBTVIntegrationTestCase
@end

@implementation TVXCUIApplicationHelperTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];
}

- (void)testQueringSpringboard
{
  [self goToHeadBoardPage];
  XCTAssertTrue([FBHomeboardApplication fb_homeboard].icons[@"Settings"].exists);
}

- (void)testTappingAppOnSpringboard
{
  [self goToHeadBoardPage];
  NSError *error;
  XCTAssertTrue([[FBHomeboardApplication fb_homeboard] fb_selectApplicationWithIdentifier:@"Settings" error:&error]);
  XCTAssertNil(error);
  XCTAssertTrue([FBApplication fb_activeApplication].cells[@"General"].exists);
}

- (void)testWaitingForSpringboard
{
  NSError *error;
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  XCTAssertTrue([[FBHomeboardApplication fb_homeboard] fb_waitUntilApplicationBoardIsVisible:&error]);
  XCTAssertNil(error);
  XCTAssertTrue([FBHomeboardApplication fb_homeboard].icons[@"Settings"].fb_isVisible);
}

- (void)testApplicationTree
{
  [self.testedApplication query];
  [self.testedApplication resolve];
  XCTAssertNotNil(self.testedApplication.fb_tree);
  XCTAssertNotNil(self.testedApplication.fb_accessibilityTree);
}

- (void)testDeactivateApplication
{
  [self.testedApplication query];
  [self.testedApplication resolve];
  NSError *error;
  XCTAssertTrue([self.testedApplication fb_deactivateWithDuration:1 error:&error]);
  XCTAssertNil(error);
  XCTAssertTrue(self.testedApplication.buttons[@"Alerts"].exists);
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"Alerts"].fb_isVisible);
}

- (void)testActiveApplication
{
  XCTAssertTrue([FBApplication fb_activeApplication].buttons[@"Alerts"].fb_isVisible);
  [self goToHeadBoardPage];
  XCTAssertTrue([FBApplication fb_activeApplication].icons[@"Settings"].fb_isVisible);
}

@end
