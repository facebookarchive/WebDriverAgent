/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBMathUtils.h"
#import "XCUICoordinate.h"
#import "XCUICoordinate+FBFix.h"
#import "XCUIElementDouble.h"

@interface XCUICoordinateFix : XCTestCase
@property (nonatomic, strong, nullable) XCUIElement *mockElement;
@property (nonatomic, strong, nullable) XCUICoordinate *defaultCoordinate;
@end

@implementation XCUICoordinateFix

- (void)setUp
{
  [super setUp];
  XCUIElementDouble *element = [XCUIElementDouble new];
  element.frame = CGRectMake(1, 2, 9, 10);
  self.mockElement = (XCUIElement *)element;
  self.defaultCoordinate = [[XCUICoordinate alloc] initWithElement:self.mockElement normalizedOffset:CGVectorMake(0.0, 0.0)];
}

- (void)testCoordinateWithElement
{
  XCUICoordinate *coordinate = [[XCUICoordinate alloc] initWithElement:self.mockElement normalizedOffset:CGVectorMake(0.0, 0.0)];
  XCTAssertTrue(FBPointFuzzyEqualToPoint(coordinate.fb_screenPoint, CGPointMake(1, 2), 0.1));
}

- (void)testCoordinateWithElementWithOffset
{
  XCUICoordinate *coordinate = [[XCUICoordinate alloc] initWithElement:self.mockElement normalizedOffset:CGVectorMake(0.5, 0.5)];
  XCTAssertTrue(FBPointFuzzyEqualToPoint(coordinate.fb_screenPoint, CGPointMake(5.5, 7), 0.1));
}

- (void)testCoordinateWithCoordinate
{
  XCUICoordinate *coordinate = [[XCUICoordinate alloc] initWithCoordinate:self.defaultCoordinate pointsOffset:CGVectorMake(0, 0)];
  XCTAssertTrue(FBPointFuzzyEqualToPoint(coordinate.fb_screenPoint, CGPointMake(1, 2), 0.1));
}

- (void)testCoordinateWithCoordinateWithOffset
{
  XCUICoordinate *coordinate = [[XCUICoordinate alloc] initWithCoordinate:self.defaultCoordinate pointsOffset:CGVectorMake(1, 2)];
  XCTAssertTrue(FBPointFuzzyEqualToPoint(coordinate.fb_screenPoint, CGPointMake(2, 4), 0.1));
}

- (void)testCoordinateWithCoordinateWithOffsetOffBounds
{
  XCUICoordinate *coordinate = [[XCUICoordinate alloc] initWithCoordinate:self.defaultCoordinate pointsOffset:CGVectorMake(200, 200)];
  XCTAssertTrue(FBPointFuzzyEqualToPoint(coordinate.fb_screenPoint, CGPointMake(10, 12), 0.1));
}

@end
