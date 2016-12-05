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
@end

@implementation XCUIElementHelpersTests

- (void)testGettingWDProperties
{
  NSDictionary *properties = [FBElementUtils wdProperties];
  XCTAssertTrue([properties.allKeys containsObject:@"wdName"]);
  
  NSArray *wdProperties = [properties.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginsWith[c] 'wd'"]];
  XCTAssertTrue(wdProperties.count > 0);
  XCTAssertEqual(properties.count, wdProperties.count);
  
  NSArray *nonWDProperties = [properties.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT(SELF beginsWith[c] 'wd')"]];
  XCTAssertEqual(nonWDProperties.count, 0);
  
  NSArray *allGetters = [[FBElementUtils wdProperties] allValues];
  NSArray *filteredGetters = [allGetters filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginsWith[c] 'is'"]];
  XCTAssertTrue(filteredGetters.count > 0);
}

@end
