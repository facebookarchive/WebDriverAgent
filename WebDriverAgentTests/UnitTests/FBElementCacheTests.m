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
  XCUIElementDouble *el1 = XCUIElementDouble.new;
  el1.wdUID = @"1";
  XCUIElementDouble *el2 = XCUIElementDouble.new;
  el2.wdUID = @"2";
  NSString *firstUUID = [self.cache storeElement:(XCUIElement *)el1];
  NSString *secondUUID = [self.cache storeElement:(XCUIElement *)el2];
  XCTAssertEqualObjects(firstUUID, el1.wdUID);
  XCTAssertEqualObjects(secondUUID, el2.wdUID);
}

- (void)testFetchingElement
{
  XCUIElement *element = (XCUIElement *)XCUIElementDouble.new;
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
  NSString *uuid = [self.cache storeElement:(XCUIElement *)XCUIElementDouble.new];
  XCUIElementDouble *element = (XCUIElementDouble *)[self.cache elementForUUID:uuid];
  XCTAssertTrue(element.didResolve);
}

- (void)testLinearCacheExpulsion
{
  const int ELEMENT_COUNT = 1050;
  
  NSMutableArray *elements = [NSMutableArray arrayWithCapacity:ELEMENT_COUNT];
  NSMutableArray *elementIds = [NSMutableArray arrayWithCapacity:ELEMENT_COUNT];
  for(int i = 0; i < ELEMENT_COUNT; i++) {
    XCUIElementDouble *el = XCUIElementDouble.new;
    el.wdUID = [NSString stringWithFormat:@"%@", @(i)];
    [elements addObject:(XCUIElement *)el];
  }
  
  // The capacity of the cache is limited to 1024 elements. Add 1050
  // elements and make sure:
  // - The first 26 elements are no longer present in the cache
  // - The remaining 1024 elements are present in the cache
  for(int i = 0; i < ELEMENT_COUNT; i++) {
    [elementIds addObject:[self.cache storeElement:elements[i]]];
  }
  
  for(int i = 0; i < ELEMENT_COUNT - ELEMENT_CACHE_SIZE; i++) {
    XCTAssertNil([self.cache elementForUUID:elementIds[i]]);
  }
  for(int i = ELEMENT_COUNT - ELEMENT_CACHE_SIZE; i < ELEMENT_COUNT; i++) {
    XCTAssertEqual(elements[i], [self.cache elementForUUID:elementIds[i]]);
  }
}

- (void)testMRUCacheExpulsion
{
  const int ELEMENT_COUNT = 1050;
  const int ACCESSED_ELEMENT_COUNT = 24;
  
  NSMutableArray *elements = [NSMutableArray arrayWithCapacity:ELEMENT_COUNT];
  NSMutableArray *elementIds = [NSMutableArray arrayWithCapacity:ELEMENT_COUNT];
  for(int i = 0; i < ELEMENT_COUNT; i++) {
    XCUIElementDouble *el = XCUIElementDouble.new;
    el.wdUID = [NSString stringWithFormat:@"%@", @(i)];
    [elements addObject:(XCUIElement *)el];
  }
  
  // The capacity of the cache is limited to 1024 elements. Add 1050
  // elements, but with a twist: access the first 24 elements before
  // adding the last 50 elements. Then, make sure:
  // - The first 24 elements are present in the cache
  // - The next 26 elements are not present in the cache
  // - The remaining 1000 elements are present in the cache
  for(int i = 0; i < ELEMENT_CACHE_SIZE; i++) {
    [elementIds addObject:[self.cache storeElement:elements[i]]];
  }
  
  for(int i = 0; i < ACCESSED_ELEMENT_COUNT; i++) {
    [self.cache elementForUUID:elementIds[i]];
  }
     
  for(int i = ELEMENT_CACHE_SIZE; i < ELEMENT_COUNT; i++) {
    [elementIds addObject:[self.cache storeElement:elements[i]]];
  }
  
  for(int i = 0; i < ACCESSED_ELEMENT_COUNT; i++) {
    XCTAssertEqual(elements[i], [self.cache elementForUUID:elementIds[i]]);
  }
  for(int i = ACCESSED_ELEMENT_COUNT; i < ELEMENT_COUNT - ELEMENT_CACHE_SIZE + ACCESSED_ELEMENT_COUNT; i++) {
    XCTAssertNil([self.cache elementForUUID:elementIds[i]]);
  }
  for(int i = ELEMENT_COUNT - ELEMENT_CACHE_SIZE + ACCESSED_ELEMENT_COUNT; i < ELEMENT_COUNT; i++) {
    XCTAssertEqual(elements[i], [self.cache elementForUUID:elementIds[i]]);
  }
}

@end
