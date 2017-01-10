/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBElementUtils.h"

@interface XCUIElementHelpersTests : XCTestCase
@property (nonatomic) NSDictionary *namesMapping;
@end

@implementation XCUIElementHelpersTests

- (void)setUp
{
  [super setUp];
  self.namesMapping = [FBElementUtils wdAttributeNamesMapping];
}

- (void)testMappingContainsNamesAndAliases
{
  XCTAssertTrue([self.namesMapping.allKeys containsObject:@"wdName"]);
  XCTAssertTrue([self.namesMapping.allKeys containsObject:@"name"]);
}

- (void)testMappingContainsCorrectValueForAttrbutesWithoutGetters
{
  XCTAssertTrue([[self.namesMapping objectForKey:@"label"] isEqualToString:@"wdLabel"]);
  XCTAssertTrue([[self.namesMapping objectForKey:@"wdLabel"] isEqualToString:@"wdLabel"]);
}

- (void)testMappingContainsCorrectValueForAttrbutesWithGetters
{
  XCTAssertTrue([[self.namesMapping objectForKey:@"visible"] isEqualToString:@"isWDVisible"]);
  XCTAssertTrue([[self.namesMapping objectForKey:@"wdVisible"] isEqualToString:@"isWDVisible"]);
}

- (void)testEachPropertyHasAlias
{
  NSArray *aliases = [self.namesMapping.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(SELF beginsWith[c] 'wd')"]];
  NSArray *names = [self.namesMapping.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginsWith[c] 'wd'"]];
  XCTAssertEqual(aliases.count, names.count);
}

@end
