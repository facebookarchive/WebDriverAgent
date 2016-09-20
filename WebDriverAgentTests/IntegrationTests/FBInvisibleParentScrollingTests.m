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

@interface FBInvisibleParentScrollingTests : FBIntegrationTestCase

@end

@implementation FBInvisibleParentScrollingTests

- (void)setUp {
    [super setUp];
    [self goToInvisibleScrollingPage];
}

- (void)testInvisibleParentScrolling {
    NSString *cellName = @"WDA";
    NSError *error;
    FBAssertInvisibleCell(cellName);
    XCTAssertTrue([FBCellElementWithLabel(cellName) fb_scrollToVisibleWithError:&error]);
    XCTAssertNil(error);
    FBAssertVisibleCell(cellName);
}

@end
