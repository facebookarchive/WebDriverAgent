/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <XCTest/XCTest.h>

#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElementDouble.h"

@interface FBElementSnapshotTests : XCTestCase
@end

@implementation FBElementSnapshotTests

- (void)testUniqueTypesFiltering {
  NSMutableArray *elements = [NSMutableArray new];
  XCUIElementDouble *el1 = [XCUIElementDouble new];
  [elements addObject:el1];
  XCUIElementDouble *el2 = [XCUIElementDouble new];
  el2.elementType = XCUIElementTypeAlert;
  el2.wdType = @"XCUIElementTypeAlert";
  [elements addObject:el2];
  XCUIElementDouble *el3 = [XCUIElementDouble new];
  [elements addObject:el3];
  
  XCTAssertNotEqual(el1.elementType, el2.elementType);
  XCTAssertFalse([el1.wdType isEqualToString: el2.wdType]);
  XCTAssertEqual(el1.elementType, el3.elementType);
  XCTAssertTrue([el1.wdType isEqualToString: el3.wdType]);

  NSSet *result = [XCElementSnapshot fb_getUniqueTypes:elements];
  XCTAssertEqual([result count], 2);
}

@end
