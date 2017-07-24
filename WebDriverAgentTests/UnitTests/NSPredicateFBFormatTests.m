/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBPredicate.h"
#import "NSPredicate+FBFormat.h"

@interface NSPredicateFBFormatTests : XCTestCase
@end

@implementation NSPredicateFBFormatTests

- (void)testFormattingForExistingProperty
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"wdName == 'blabla'"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingForExistingPropertyOnTheRightSide
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"0 == wdAccessible"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingForExistingPropertyShortcut
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"visible == 1"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingForComplexExpression
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"visible == 1 AND type == 'blabla'"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingForValidExpressionWOKeys
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"1 = 1"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingForExistingComplexProperty
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"wdRect.x == '0'"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingForExistingComplexPropertyWOPrefix
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"rect.x == '0'"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:expr]);
}
                       
- (void)testFormattingForPredicateWithUnknownKey
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"title == 'blabla'"];
  XCTAssertThrows([NSPredicate fb_formatSearchPredicate:expr]);
}

- (void)testFormattingFBPredicate
{
  NSPredicate *predicate = [FBPredicate predicateWithFormat:@"visible == 1"];
  XCTAssertNotNil([NSPredicate fb_formatSearchPredicate:predicate]);
}

@end
