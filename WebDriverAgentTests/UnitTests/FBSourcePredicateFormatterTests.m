/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBSearchPredicatesFormatter.h"

@interface FBSourcePredicateFormatterTests : XCTestCase
@end

@implementation FBSourcePredicateFormatterTests

- (void)testFormattingForDifferentTypesOfSearchPredicates
{
  NSArray<NSString *> *predicateExpressions = @[
    // existing FBElement property
    @"wdName == 'blabla'",
    // existing FBElement property on the right side
    @"0 == wdAccessible",
    // property shortcut w/o 'wd' prefix
    @"visible == 1",
    // complex expression
    @"visible == 1 AND type == 'blabla'",
    // valid expression without keys
    @"1 = 1",
    // accessing complex property
    @"wdRect.x == '0'",
    // accessing complex property w/o prefix
    @"rect.x == '0'"
  ];
  for (NSString* strExp in predicateExpressions) {
    NSPredicate *expr = [NSPredicate predicateWithFormat:strExp];
    XCTAssertNotNil([FBSearchPredicatesFormatter fb_formatSearchPredicate:expr]);
  }
}

- (void)testFormattingForPredicateWithUnknownKey
{
  NSPredicate *expr = [NSPredicate predicateWithFormat:@"title == 'blabla'"];
  XCTAssertThrowsSpecificNamed([FBSearchPredicatesFormatter fb_formatSearchPredicate:expr], NSException, FBUnknownPredicateKeyException);
}

@end
