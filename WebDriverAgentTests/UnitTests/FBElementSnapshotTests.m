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
#import "XCElementDouble.h"

@interface FBElementSnapshotTests : XCTestCase
@end

@implementation FBElementSnapshotTests

- (void)testSnapshotXPathPresentation {
  NSMutableArray *elements = [NSMutableArray new];
  XCElementDouble *el1 = [XCElementDouble new];
  [elements addObject:el1];
  XCElementDouble *el2 = [XCElementDouble new];
  el2.elementType = XCUIElementTypeAlert;
  el2.wdType = @"XCUIElementTypeAlert";
  [elements addObject:el2];
  XCElementDouble *el3 = [XCElementDouble new];
  [elements addObject:el3];
  
  XCTAssertNotEqual(el1.elementType, el2.elementType);
  XCTAssertFalse([el1.wdType isEqualToString: el2.wdType]);
  XCTAssertEqual(el1.elementType, el3.elementType);
  XCTAssertTrue([el1.wdType isEqualToString: el3.wdType]);

  NSSet *result = [XCElementSnapshot fb_getUniqueTypes:elements];
  XCTAssertEqual([result count], 2);
}

@end
