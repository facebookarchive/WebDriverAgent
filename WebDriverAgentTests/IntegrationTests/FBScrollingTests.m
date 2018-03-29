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
#import "FBTestMacros.h"

#import "FBMacros.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"

#define FBCellElementWithLabel(label) ([self.testedApplication descendantsMatchingType:XCUIElementTypeAny][label])
#define FBAssertVisibleCell(label) FBAssertWaitTillBecomesTrue(FBCellElementWithLabel(label).fb_isVisible)
#define FBAssertInvisibleCell(label) FBAssertWaitTillBecomesTrue(!FBCellElementWithLabel(label).fb_isVisible)

@interface FBScrollingTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *scrollView;
@end

@implementation FBScrollingTests

+ (BOOL)shouldShowCells
{
  return YES;
}

- (void)setUp
{
  [super setUp];
  [self launchApplication];
  [self goToScrollPageWithCells:NO];
  self.scrollView = [[self.testedApplication.query descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:@"scrollView"].element;
  [self.scrollView resolve];
}

- (void)testCellVisibility
{
  FBAssertVisibleCell(@"0");
  FBAssertVisibleCell(@"10");
  FBAssertInvisibleCell(@"30");
  FBAssertInvisibleCell(@"50");
}

- (void)testSimpleScroll
{
  FBAssertVisibleCell(@"0");
  FBAssertVisibleCell(@"10");
  [self.scrollView fb_scrollDownByNormalizedDistance:1.0];
  FBAssertInvisibleCell(@"0");
  FBAssertInvisibleCell(@"10");
  XCTAssertTrue(self.testedApplication.staticTexts.count > 0);
  // Scroll up might sometimes be unstable
  // (it depends on Simulator window size and the actual machine perfomance)
  for (int retry = 0; retry < 5; ++retry) {
    [self.scrollView fb_scrollUpByNormalizedDistance:1.0];
    if (FBCellElementWithLabel(@"0").fb_isVisible) {
      break;
    }
  }
  FBAssertVisibleCell(@"0");
  FBAssertVisibleCell(@"10");
}

- (void)testScrollToVisible
{
  NSString *cellName = @"30";
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
