/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBApplication.h"
#import "FBIntegrationTestCase.h"
#import "FBMacros.h"
#import "FBTestMacros.h"
#import "XCUIDevice+FBHelpers.h"

@interface XCUIDeviceHelperTests : FBIntegrationTestCase
@end

@implementation XCUIDeviceHelperTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testScreenshot
{
  NSError *error = nil;
  NSData *screenshotData = [[XCUIDevice sharedDevice] fb_screenshotWithError:&error];
  XCTAssertNotNil([UIImage imageWithData:screenshotData]);
  XCTAssertNil(error);
}

- (void)testWifiAddress
{
  NSString *adderss = [XCUIDevice sharedDevice].fb_wifiIPAddress;
  if (!adderss) {
    return;
  }
  NSRange range = [adderss rangeOfString:@"^([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})" options:NSRegularExpressionSearch];
  XCTAssertTrue(range.location != NSNotFound);
}

- (void)testGoToHomeScreen
{
  NSError *error;
  XCTAssertTrue([[XCUIDevice sharedDevice] fb_goToHomescreenWithError:&error]);
  XCTAssertNil(error);
  XCTAssertTrue([FBApplication fb_activeApplication].icons[@"Safari"].exists);
}

- (void)testLockUnlockScreen
{
  XCTAssertFalse([[XCUIDevice sharedDevice] fb_isScreenLocked]);
  NSError *error;
  XCTAssertTrue([[XCUIDevice sharedDevice] fb_lockScreen:&error]);
  XCTAssertTrue([[XCUIDevice sharedDevice] fb_isScreenLocked]);
  XCTAssertNil(error);
  XCTAssertTrue([[XCUIDevice sharedDevice] fb_unlockScreen:&error]);
  XCTAssertFalse([[XCUIDevice sharedDevice] fb_isScreenLocked]);
  XCTAssertNil(error);
}

- (void)testUrlSchemeActivation
{
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    return;
  }
  
  NSError *error;
  XCTAssertTrue([XCUIDevice.sharedDevice fb_openUrl:@"https://apple.com" error:&error]);
  FBAssertWaitTillBecomesTrue([FBApplication.fb_activeApplication.bundleID isEqualToString:@"com.apple.mobilesafari"]);
  XCTAssertNil(error);
}

@end
