/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBElementTypeTransformer.h"

@interface FBElementTypeTransformerTests : XCTestCase
@end

@implementation FBElementTypeTransformerTests

- (void)testStringWithElementType
{
  XCTAssertEqualObjects(@"XCUIElementTypeAny", [FBElementTypeTransformer stringWithElementType:XCUIElementTypeAny]);
  XCTAssertEqualObjects(@"XCUIElementTypeIcon", [FBElementTypeTransformer stringWithElementType:XCUIElementTypeIcon]);
  XCTAssertEqualObjects(@"XCUIElementTypeTab", [FBElementTypeTransformer stringWithElementType:XCUIElementTypeTab]);
  XCTAssertEqualObjects(@"XCUIElementTypeOther", [FBElementTypeTransformer stringWithElementType:XCUIElementTypeOther]);
}

- (void)testShortStringWithElementType
{
  XCTAssertEqualObjects(@"Any", [FBElementTypeTransformer shortStringWithElementType:XCUIElementTypeAny]);
  XCTAssertEqualObjects(@"Icon", [FBElementTypeTransformer shortStringWithElementType:XCUIElementTypeIcon]);
  XCTAssertEqualObjects(@"Tab", [FBElementTypeTransformer shortStringWithElementType:XCUIElementTypeTab]);
  XCTAssertEqualObjects(@"Other", [FBElementTypeTransformer shortStringWithElementType:XCUIElementTypeOther]);
}

- (void)testElementTypeWithElementTypeName
{
  XCTAssertEqual(XCUIElementTypeAny, [FBElementTypeTransformer elementTypeWithTypeName:@"XCUIElementTypeAny"]);
  XCTAssertEqual(XCUIElementTypeIcon, [FBElementTypeTransformer elementTypeWithTypeName:@"XCUIElementTypeIcon"]);
  XCTAssertEqual(XCUIElementTypeTab, [FBElementTypeTransformer elementTypeWithTypeName:@"XCUIElementTypeTab"]);
  XCTAssertEqual(XCUIElementTypeOther, [FBElementTypeTransformer elementTypeWithTypeName:@"XCUIElementTypeOther"]);
  XCTAssertThrows([FBElementTypeTransformer elementTypeWithTypeName:@"Whatever"]);
  XCTAssertThrows([FBElementTypeTransformer elementTypeWithTypeName:nil]);
}

@end
