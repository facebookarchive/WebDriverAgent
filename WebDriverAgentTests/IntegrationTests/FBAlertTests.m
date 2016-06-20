/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <WebDriverAgentLib/FBAlert.h>

#import "FBIntegrationTestCase.h"

@interface FBAlertTests : FBIntegrationTestCase
@end

@implementation FBAlertTests

- (void)testAcceptingAlert
{
  [self.testedApplication.buttons[@"Show alert"] tap];
  [[FBAlert alertWithApplication:self.testedApplication] acceptWithError:nil];
  sleep(1);
  XCTAssertTrue(self.testedApplication.alerts.count == 0, @"Alert should be dismissed");
}

@end
