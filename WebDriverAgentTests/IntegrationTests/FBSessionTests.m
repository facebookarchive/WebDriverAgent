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
#import "FBXCodeCompatibility.h"

@interface FBSessionTests : FBIntegrationTestCase
@property (nonatomic) FBSession *session;
@end


static NSString *const SETTINGS_APP_ID = @"com.apple.Preferences";
static NSString *const SPRINGBOARD_APP_ID = @"com.apple.springboard";

@implementation FBSessionTests

- (void)setUp
{
  [super setUp];
  [self launchApplication];
  
  self.session = [FBSession sessionWithApplication:FBApplication.fb_activeApplication];
}

- (void)testSettingsAppCanBeOpenedInScopeOfTheCurrentSession
{
  FBApplication *testedApp = self.session.activeApplication;
  @try {
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
    [self.session launchApplicationWithBundleId:SETTINGS_APP_ID];
    XCTAssertEqualObjects(SETTINGS_APP_ID, self.session.activeApplication.bundleID);
    XCTAssertEqual([self.session applicationStateWithBundleId:SETTINGS_APP_ID], 4);
    [self.session activateApplicationWithBundleId:testedApp.bundleID];
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
    XCTAssertEqual([self.session applicationStateWithBundleId:testedApp.bundleID], 4);
  } @catch (NSException *e) {
    if (!SYSTEM_VERSION_LESS_THAN(@"11.0")) {
      @throw e;
    }
    XCTAssertEqualObjects(e.name, FBApplicationMethodNotSupportedException);
  }
}

- (void)testSettingsAppCanBeReopenedInScopeOfTheCurrentSession
{
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    return;
  }
  FBApplication *testedApp = self.session.activeApplication;
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
  [self.session launchApplicationWithBundleId:SETTINGS_APP_ID];
  [self.session terminateApplicationWithBundleId:SETTINGS_APP_ID];
  XCTAssertEqualObjects(SPRINGBOARD_APP_ID, self.session.activeApplication.bundleID);
  [self.session launchApplicationWithBundleId:SETTINGS_APP_ID];
  XCTAssertEqualObjects(SETTINGS_APP_ID, self.session.activeApplication.bundleID);
}

- (void)testMainAppCanBeReactivatedInScopeOfTheCurrentSession
{
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    return;
  }
  FBApplication *testedApp = self.session.activeApplication;
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
  [self.session launchApplicationWithBundleId:SETTINGS_APP_ID];
  XCTAssertEqualObjects(SETTINGS_APP_ID, self.session.activeApplication.bundleID);
  [self.session activateApplicationWithBundleId:testedApp.bundleID];
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
}

- (void)testMainAppCanBeRestartedInScopeOfTheCurrentSession
{
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    return;
  }
  FBApplication *testedApp = self.session.activeApplication;
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
  [self.session terminateApplicationWithBundleId:testedApp.bundleID];
  XCTAssertEqualObjects(SPRINGBOARD_APP_ID, self.session.activeApplication.bundleID);
  [self.session launchApplicationWithBundleId:testedApp.bundleID];
  XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
}

@end
