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
#import "XCUIDevice+FBHelpers.h"

@interface XCUIDeviceHelperTests : FBIntegrationTestCase
@end

@implementation XCUIDeviceHelperTests

- (void)testScreenshot
{
  XCTAssertNotNil([UIImage imageWithData:[XCUIDevice sharedDevice].fb_screenshot]);
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

@end
