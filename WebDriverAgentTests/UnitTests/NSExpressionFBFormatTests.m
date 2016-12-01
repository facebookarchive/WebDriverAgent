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

@interface NSExpressionFBFormatTests : XCTestCase
@end

@implementation NSExpressionFBFormatTests

- (void)testFormattingForExistingProperty
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"wdName"];
  XCTAssertNotNil([NSExpression fb_wdExpressionWithExpression:expr]);
}

- (void)testFormattingForExistingPropertyShortcut
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"visible"];
  XCTAssertNotNil([NSExpression fb_wdExpressionWithExpression:expr]);
}

- (void)testFormattingForValidExpressionWOKeys
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"1"];
  XCTAssertNotNil([NSExpression fb_wdExpressionWithExpression:expr]);
}

- (void)testFormattingForExistingComplexProperty
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"wdRect.x"];
  XCTAssertNotNil([NSExpression fb_wdExpressionWithExpression:expr]);
}

- (void)testFormattingForExistingComplexPropertyWOPrefix
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"rect.x"];
  XCTAssertNotNil([NSExpression fb_wdExpressionWithExpression:expr]);
}

- (void)testFormattingForPredicateWithUnknownKey
{
  NSExpression *expr = [NSExpression expressionWithFormat:@"title"];
  XCTAssertThrowsSpecificNamed([NSExpression fb_wdExpressionWithExpression:expr], NSException, FBUnknownPredicateKeyException);
}

@end
