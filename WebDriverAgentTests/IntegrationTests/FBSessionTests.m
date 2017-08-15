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

@interface FBSessionTests : FBIntegrationTestCase
@property (nonatomic) FBSession *session;
@end


static NSString *const SETTINGS_BUNDLE_ID = @"com.apple.Preferences";

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
    [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID];
    XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.activeApplication.bundleID);
    XCTAssertEqual([self.session applicationStateWithBundleId:SETTINGS_BUNDLE_ID], 4);
    [self.session activateApplicationWithBundleId:testedApp.bundleID];
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
    XCTAssertEqual([self.session applicationStateWithBundleId:testedApp.bundleID], 4);
  } @catch (NSException *e) {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
      @throw e;
    }
    XCTAssertEqualObjects(e.name, FBApplicationMethodNotSupportedException);
  }
}

- (void)testSettingsAppCanBeReopenedInScopeOfTheCurrentSession
{
  @try {
    FBApplication *testedApp = self.session.activeApplication;
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
    [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID];
    [self.session terminateApplicationWithBundleId:SETTINGS_BUNDLE_ID];
    XCTAssertEqualObjects(SPRINGBOARD_BUNDLE_ID, self.session.activeApplication.bundleID);
    [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID];
    XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.activeApplication.bundleID);
  } @catch (NSException *e) {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
      @throw e;
    }
    XCTAssertEqualObjects(e.name, FBApplicationMethodNotSupportedException);
  }
}

- (void)testMainAppCanBeReactivatedInScopeOfTheCurrentSession
{
  @try {
    FBApplication *testedApp = self.session.activeApplication;
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
    [self.session launchApplicationWithBundleId:SETTINGS_BUNDLE_ID];
    XCTAssertEqualObjects(SETTINGS_BUNDLE_ID, self.session.activeApplication.bundleID);
    [self.session activateApplicationWithBundleId:testedApp.bundleID];
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
  } @catch (NSException *e) {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
      @throw e;
    }
    XCTAssertEqualObjects(e.name, FBApplicationMethodNotSupportedException);
  }
}

- (void)testMainAppCanBeRestartedInScopeOfTheCurrentSession
{
  @try {
    FBApplication *testedApp = self.session.activeApplication;
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
    [self.session terminateApplicationWithBundleId:testedApp.bundleID];
    XCTAssertEqualObjects(SPRINGBOARD_BUNDLE_ID, self.session.activeApplication.bundleID);
    [self.session launchApplicationWithBundleId:testedApp.bundleID];
    XCTAssertEqualObjects(testedApp.bundleID, self.session.activeApplication.bundleID);
  } @catch (NSException *e) {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
      @throw e;
    }
    XCTAssertEqualObjects(e.name, FBApplicationMethodNotSupportedException);
  }
}

@end
