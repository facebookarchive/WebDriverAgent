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
#import "XCUIElementDouble.h"

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
  NSUInteger firstIndex = [self.cache storeElement:(XCUIElement *)XCUIElementDouble.new];
  NSUInteger secondIndex = [self.cache storeElement:(XCUIElement *)XCUIElementDouble.new];
  XCTAssert(firstIndex > 0, @"Stored index should be higher than 0");
  XCTAssert(secondIndex > 0, @"Stored index should be higher than 0");
  XCTAssert(firstIndex != secondIndex, @"Stored indexes should be different");
}

- (void)testFetchingElement
{
  XCUIElement *element = (XCUIElement *)XCUIElementDouble.new;
  NSUInteger index = [self.cache storeElement:element];
  XCTAssert(index > 0, @"Stored index should be higher than 0");
  XCTAssertEqual(element, [self.cache elementForIndex:index]);
}

- (void)testFetchingBadIndex
{
  XCTAssertNil([self.cache elementForIndex:100]);
}

- (void)testResolvingFetchedElement
{
  NSUInteger index = [self.cache storeElement:(XCUIElement *)XCUIElementDouble.new];
  XCUIElementDouble *element = (XCUIElementDouble *)[self.cache elementForIndex:index];
  XCTAssertTrue(element.didResolve);
}

- (void)testAlertObstructionCheckWhenFetchingElement
{
  XCUIElementDouble *elementDouble = XCUIElementDouble.new;
  elementDouble.fb_isObstructedByAlert = YES;
  NSUInteger index = [self.cache storeElement:(XCUIElement *)elementDouble];
  XCTAssertThrows([self.cache elementForIndex:index]);
}

@end
