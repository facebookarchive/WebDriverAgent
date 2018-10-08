/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBTVIntegrationTestCase.h"
#import "FBFindElementCommands.h"
#import "XCUIElement+FBAccessibility.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@interface FBTVElementAttributeTests : FBTVIntegrationTestCase
@end

@implementation FBTVElementAttributeTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToAttributesPage];
  });
}

- (void)testElementAccessibilityAttributes
{
  // "Button" is accessibility element, and therefore isn't accessibility container
  XCUIElement *buttonElement = self.testedApplication.buttons[@"Select me"];
  XCTAssertTrue(buttonElement.exists);
  XCTAssertTrue(buttonElement.fb_isAccessibilityElement);
  XCTAssertFalse(buttonElement.isWDAccessibilityContainer);
}

- (void)testContainerAccessibilityAttributes
{
  // "not_accessible" isn't accessibility element, but contains accessibility elements, so it is accessibility container
  XCUIElement *inaccessibleButtonElement = self.testedApplication.buttons[@"Not accessible"];
  XCTAssertTrue(inaccessibleButtonElement.exists);
  XCTAssertFalse(inaccessibleButtonElement.fb_isAccessibilityElement);
  XCTAssertTrue(inaccessibleButtonElement.isWDAccessibilityContainer);
}

- (void)testIgnoredAccessibilityAttributes
{
  // Images are neither accessibility elements nor contain them, so both checks should fail
  XCUIElement *imageElement = [self.testedApplication.images elementBoundByIndex:0];
  XCTAssertTrue(imageElement.exists);
  XCTAssertFalse(imageElement.fb_isAccessibilityElement);
  XCTAssertFalse(imageElement.isWDAccessibilityContainer);
}

- (void)testButtonAttributes
{
  XCUIElement *element = self.testedApplication.buttons[@"Select me"];
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeButton");
  XCTAssertEqualObjects(element.wdName, @"Select me");
  XCTAssertEqualObjects(element.wdLabel, @"Select me");
  XCTAssertNil(element.wdValue);
  [self select:element];
  [element resolve];
  XCTAssertEqual(element.wdValue.boolValue, YES);
}

- (void)testLabelAttributes
{
  XCUIElement *element = self.testedApplication.staticTexts[@"Text Field"];
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeStaticText");
  XCTAssertEqualObjects(element.wdName, @"Text Field");
  XCTAssertEqualObjects(element.wdLabel, @"Text Field");
  XCTAssertEqualObjects(element.wdValue, @"Text Field");
}

- (void)testTextFieldAttributes
{
  XCUIElement *element = self.testedApplication.textFields[@"Value"];
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeTextField");
  XCTAssertNil(element.wdName);
  XCTAssertEqualObjects(element.wdLabel, @"");
  XCTAssertEqualObjects(element.wdValue, @"Value");
}

- (void)testTextFieldWithAccessibilityIdentifiersAttributes
{
  XCUIElement *element = self.testedApplication.textFields[@"aIdentifier"];
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeTextField");
  XCTAssertEqualObjects(element.wdName, @"aIdentifier");
  XCTAssertEqualObjects(element.wdLabel, @"aLabel");
  XCTAssertEqualObjects(element.wdValue, @"Value2");
}

- (void)testSegmentedControlAttributes
{
  XCUIElement *element = self.testedApplication.segmentedControls.element;
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeSegmentedControl");
  XCTAssertNil(element.wdName);
  XCTAssertNil(element.wdLabel);
  XCTAssertNil(element.wdValue);
}

- (void)testActivityIndicatorAttributes
{
  XCUIElement *element = self.testedApplication.activityIndicators.element;
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeActivityIndicator");
  XCTAssertEqualObjects(element.wdName, @"Progress halted");
  XCTAssertEqualObjects(element.wdLabel, @"Progress halted");
  XCTAssertEqualObjects(element.wdValue, @"0");
}

- (void)testPageIndicatorAttributes
{
  XCUIElement *element = self.testedApplication.pageIndicators.element;
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypePageIndicator");
  XCTAssertNil(element.wdName);
  XCTAssertNil(element.wdLabel);
  XCTAssertEqualObjects(element.wdValue, @"page 1 of 3");
}

- (void)testTextViewAttributes
{
  XCUIElement *element = self.testedApplication.textViews.element;
  XCTAssertTrue(element.exists);
  XCTAssertEqualObjects(element.wdType, @"XCUIElementTypeTextView");
  XCTAssertNil(element.wdName);
  XCTAssertNil(element.wdLabel);
  XCTAssertEqualObjects(element.wdValue, @"Text Field long text");
}

@end
