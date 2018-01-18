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
#import "FBApplication.h"
#import "FBMacros.h"
#import "FBSession.h"
#import "FBSpringboardApplication.h"
#import "FBXCodeCompatibility.h"
#import "FBTestMacros.h"

@interface FBSessionIntegrationTests : FBIntegrationTestCase
@property (nonatomic) FBSession *session;
@end


static NSString *const SETTINGS_BUNDLE_ID = @"com.apple.Preferences";

@implementation FBSessionIntegrationTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];

  self.session = [FBSession sessionWithApplication:FBApplication.fb_activeApplication];
}

- (void)testSettingsAppCanBeOpenedInScopeOfTheCurrentSession
{
  FBApplication *testedApp = FBApplication.fb_activeApplication;
  if (!testedApp.fb_isActivateSupported) {
    return;
  }
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID arguments:nil environment:nil];
  XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.activeApplication.bundleID);
  XCTAssertEqual([self.session applicationStateWithBundleId:SETTINGS_BUNDLE_ID], 4);
  [self.session activateApplicationWithBundleId:testedApp.bundleID];
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
  XCTAssertEqual([self.session applicationStateWithBundleId:testedApp.bundleID], 4);
}

- (void)testSettingsAppCanBeReopenedInScopeOfTheCurrentSession
{
  FBApplication *testedApp = FBApplication.fb_activeApplication;
  if (!testedApp.fb_isActivateSupported) {
    return;
  }
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID arguments:nil environment:nil];
  FBAssertWaitTillBecomesTrue([SETTINGS_BUNDLE_ID isEqualToString:self.session.activeApplication.bundleID]);
  XCTAssertTrue([self.session terminateApplicationWithBundleId:SETTINGS_BUNDLE_ID]);
  FBAssertWaitTillBecomesTrue([SPRINGBOARD_BUNDLE_ID isEqualToString:self.session.activeApplication.bundleID]);
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID arguments:nil environment:nil];
  XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.activeApplication.bundleID);
}

- (void)testMainAppCanBeReactivatedInScopeOfTheCurrentSession
{
  FBApplication *testedApp = FBApplication.fb_activeApplication;
  if (!testedApp.fb_isActivateSupported) {
    return;
  }
  [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID arguments:nil environment:nil];
  XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.activeApplication.bundleID);
  [self.session activateApplicationWithBundleId:testedApp.bundleID];
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
}

- (void)testMainAppCanBeRestartedInScopeOfTheCurrentSession
{
  FBApplication *testedApp = FBApplication.fb_activeApplication;
  if (!testedApp.fb_isActivateSupported) {
    return;
  }
  XCTAssertTrue([self.session terminateApplicationWithBundleId:testedApp.bundleID]);
  XCTAssertEqualObjects(SPRINGBOARD_BUNDLE_ID, self.session.activeApplication.bundleID);
  [self.session launchApplicationWithBundleId:testedApp.bundleID arguments:nil environment:nil];
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
}

@end
