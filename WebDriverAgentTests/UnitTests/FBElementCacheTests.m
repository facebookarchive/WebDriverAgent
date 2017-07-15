/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBElementCache.h"
#import "XCElementSnapshotDouble.h"

@interface FBElementCacheTests : XCTestCase
@property (nonatomic, strong) FBElementCache *cache;
@end

@implementation FBElementCacheTests

- (void)setUp
{
  [super setUp];
  self.cache = [FBElementCache new];
}

- (void)testStoringElement
{
  NSString *firstUUID = [self.cache storeElement:(XCUIElement *)XCElementSnapshotDouble.new];
  NSString *secondUUID = [self.cache storeElement:(XCUIElement *)XCElementSnapshotDouble.new];
  XCTAssertNotNil(firstUUID, @"Stored index should be higher than 0");
  XCTAssertNotNil(secondUUID, @"Stored index should be higher than 0");
  XCTAssertNotEqualObjects(firstUUID, secondUUID, @"Stored indexes should be different");
}

- (void)testFetchingElement
{
  XCUIElement *element = (XCUIElement *)XCElementSnapshotDouble.new;
  NSString *uuid = [self.cache storeElement:element];
  XCTAssertNotNil(uuid, @"Stored index should be higher than 0");
  XCTAssertEqual(element, [self.cache elementForUUID:uuid]);
}

- (void)testFetchingBadIndex
{
  XCTAssertNil([self.cache elementForUUID:@"random"]);
}

- (void)testResolvingFetchedElement
{
  NSString *uuid = [self.cache storeElement:(XCUIElement *)XCElementSnapshotDouble.new];
  XCElementSnapshotDouble *element = (XCElementSnapshotDouble *)[self.cache elementForUUID:uuid];
  XCTAssertTrue(element.didResolve);
}

- (void)testAlertObstructionCheckWhenFetchingElement
{
  XCElementSnapshotDouble *elementDouble = XCElementSnapshotDouble.new;
  elementDouble.fb_isObstructedByAlert = YES;
  NSString *uuid = [self.cache storeElement:(XCUIElement *)elementDouble];
  XCTAssertThrows([self.cache elementForUUID:uuid]);
}

@end
