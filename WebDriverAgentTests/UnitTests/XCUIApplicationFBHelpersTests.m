/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "XCUIApplication+FBHelpers.h"

@interface XCUIApplication (FBHelpersTest)
+ (NSDictionary *)formattedRectWithFrame:(CGRect)frame;
@end

@interface XCUIApplicationFBHelpersTests : XCTestCase
@end

@implementation XCUIApplicationFBHelpersTests

- (void)setUp
{
  [super setUp];
}

- (void)testRectWithFinitePositiveNumbers
{
  NSDictionary *expected = @{@"x": @1, @"y": @2, @"width": @3, @"height": @4};
  NSDictionary *result = [XCUIApplication formattedRectWithFrame:CGRectMake(1, 2, 3, 4)];
  XCTAssertNoThrow([NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]);
  XCTAssertEqualObjects(result, expected);
}

- (void)testRectWithFiniteNegativeNumbers
{
  NSDictionary *expected = @{@"x": @(-4), @"y": @2, @"width": @3, @"height": @4};
  NSDictionary *result = [XCUIApplication formattedRectWithFrame:CGRectMake(-1, 2, -3, 4)];
  XCTAssertNoThrow([NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]);
  XCTAssertEqualObjects(result, expected);
}

- (void)testInfinitives
{
  NSDictionary *expected = @{@"x": @(0), @"y": @0, @"width": @(3), @"height": @0};
  NSDictionary *result = [XCUIApplication formattedRectWithFrame:CGRectMake(INFINITY, INFINITY, 3, INFINITY)];
  XCTAssertNoThrow([NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]);
  XCTAssertEqualObjects(result, expected);
}

@end
