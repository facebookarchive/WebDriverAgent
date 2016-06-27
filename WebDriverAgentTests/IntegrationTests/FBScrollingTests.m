/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBIntegrationTestCase.h"

#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"

#define FBCellElementWithLabel(label) ([self.testedApplication descendantsMatchingType:XCUIElementTypeAny][label])
#define FBAssertVisibleCell(label) XCTAssertTrue(FBCellElementWithLabel(label).fb_isVisible, @"Cell %@ should be visible", label)
#define FBAssertInvisibleCell(label) XCTAssertFalse(FBCellElementWithLabel(label).fb_isVisible, @"Cell %@ should be invisible", label)

@interface FBScrollingTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *tableView;
@end

@implementation FBScrollingTests

+ (BOOL)shouldUseStrippedCells
{
  return NO;
}

- (void)setUp
{
  [super setUp];
  [self gotToScrollsWithAccessibilityStrippedCells:NO];
  self.tableView = self.testedApplication.tables.element;
  [self.tableView resolve];
}

- (void)testSimpleScroll
{
  [self.tableView fb_scrollDown];
  FBAssertVisibleCell(@"20");
  [self.tableView fb_scrollUp];
  FBAssertVisibleCell(@"0");
}

- (void)testTriplePageScroll
{
  FBAssertVisibleCell(@"0");
  [self.tableView fb_scrollDown];
  [self.tableView fb_scrollDown];
  [self.tableView fb_scrollDown];
  FBAssertInvisibleCell(@"0");
  FBAssertVisibleCell(@"44");
  [self.tableView fb_scrollUp];
  [self.tableView fb_scrollUp];
  [self.tableView fb_scrollUp];
  FBAssertVisibleCell(@"0");
}

- (void)testScrollToVisible
{
  NSString *cellName = @"20";
  FBAssertInvisibleCell(cellName);
  NSError *error;
  XCTAssertTrue([FBCellElementWithLabel(cellName) fb_scrollToVisibleWithError:&error]);
  XCTAssertNil(error);
  FBAssertVisibleCell(cellName);
}

- (void)testFarScrollToVisible
{
  NSString *cellName = @"80";
  NSError *error;
  FBAssertInvisibleCell(cellName);
  XCTAssertTrue([FBCellElementWithLabel(cellName) fb_scrollToVisibleWithError:&error]);
  XCTAssertNil(error);
  FBAssertVisibleCell(cellName);
}

@end
