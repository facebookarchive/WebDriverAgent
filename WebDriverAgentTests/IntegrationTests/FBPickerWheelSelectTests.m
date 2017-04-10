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
#import "XCUIElement+FBPickerWheel.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@interface FBPickerWheelSelectTests : FBIntegrationTestCase
@end

@implementation FBPickerWheelSelectTests

- (void)setUp
{
  [super setUp];
  [self goToAttributesPage];
}

- (void)testSelectNextPickerValue
{
  XCUIElement *element = [self.testedApplication.pickerWheels elementBoundByIndex:0];
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypePickerWheel");
  NSError *error;
  NSString *previousValue = element.wdValue;
  XCTAssertTrue([element fb_selectNextOptionWithError:&error]);
  XCTAssertNotEqualObjects(previousValue, element.wdValue);
}

- (void)testSelectPreviousPickerValue
{
  XCUIElement *element = [self.testedApplication.pickerWheels elementBoundByIndex:1];
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypePickerWheel");
  NSError *error;
  NSString *previousValue = element.wdValue;
  XCTAssertTrue([element fb_selectPreviousOptionWithError:&error]);
  XCTAssertNotEqualObjects(previousValue, element.wdValue);
}

@end
