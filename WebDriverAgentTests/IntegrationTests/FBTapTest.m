/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "XCUIElement+FBTap.h"

@interface FBTapTest : XCTestCase
@end

@implementation FBTapTest

- (void)testTap
{
  XCUIApplication *app = [XCUIApplication new];
  [app launch];
  NSError *error;
  XCTAssertTrue(app.alerts.count == 0);
  [app.buttons[@"Show alert"] fb_tapWithError:&error];
  XCTAssertTrue(app.alerts.count > 0);
}

@end
