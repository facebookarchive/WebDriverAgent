/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <XCTest/XCTest.h>

#import "FBElement.h"
#import "XCElementSnapshotDouble.h"
#import "FBElementUtils.h"

@interface FBElementUtilitiesTests : XCTestCase
@end

@implementation FBElementUtilitiesTests

- (void)testTypesFiltering {
  NSMutableArray *elements = [NSMutableArray new];
  XCElementSnapshotDouble *el1 = [XCElementSnapshotDouble new];
  [elements addObject:el1];
  XCElementSnapshotDouble *el2 = [XCElementSnapshotDouble new];
  el2.elementType = XCUIElementTypeAlert;
  el2.wdType = @"XCUIElementTypeAlert";
  [elements addObject:el2];
  XCElementSnapshotDouble *el3 = [XCElementSnapshotDouble new];
  [elements addObject:el3];
  
  NSSet *result = [FBElementUtils uniqueElementTypesWithElements:elements];
  XCTAssertEqual([result count], 2);
}

@end
