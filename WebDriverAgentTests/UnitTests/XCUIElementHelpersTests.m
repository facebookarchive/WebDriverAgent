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
  NSArray *properties = [FBElementUtils wdPropertyNames];
  NSArray *wdProperties = [properties filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginsWith[c] 'wd'"]];
  XCTAssertTrue(wdProperties.count > 0);
  XCTAssertEqual(properties.count, wdProperties.count);
}

@end
