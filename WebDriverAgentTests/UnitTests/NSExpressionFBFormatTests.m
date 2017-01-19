/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "NSExpression+FBFormat.h"
#import "FBElementUtils.h"

@interface NSExpressionFBFormatTests : XCTestCase
@end

@implementation NSExpressionFBFormatTests

- (void)testFormattingForExistingProperty
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"wdName"];
  NSExpression *prop = [NSExpression fb_wdExpressionWithExpression:expr];
  XCTAssertEqualObjects([prop keyPath], @"wdName");
}

- (void)testFormattingForExistingPropertyShortcut
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"visible"];
  NSExpression *prop = [NSExpression fb_wdExpressionWithExpression:expr];
  XCTAssertEqualObjects([prop keyPath], @"isWDVisible");
}

- (void)testFormattingForValidExpressionWOKeys
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"1"];
  NSExpression *prop = [NSExpression fb_wdExpressionWithExpression:expr];
  XCTAssertEqualObjects([prop constantValue], [NSNumber numberWithInt:1]);
}

- (void)testFormattingForExistingComplexProperty
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"wdRect.x"];
  NSExpression *prop = [NSExpression fb_wdExpressionWithExpression:expr];
  XCTAssertEqualObjects([prop keyPath], @"wdRect.x");
}

- (void)testFormattingForExistingComplexPropertyWOPrefix
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"rect.x"];
  NSExpression *prop = [NSExpression fb_wdExpressionWithExpression:expr];
  XCTAssertEqualObjects([prop keyPath], @"wdRect.x");
}

- (void)testFormattingForPredicateWithUnknownKey
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"title"];
  XCTAssertThrowsSpecificNamed([NSExpression fb_wdExpressionWithExpression:expr], NSException, FBUnknownAttributeException);
}

@end
