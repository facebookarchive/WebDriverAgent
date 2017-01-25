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
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElement+FBIsVisible.h"

@interface XCElementSnapshotHelperTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *testedView;
@end

@implementation XCElementSnapshotHelperTests

- (void)setUp
{
  [super setUp];
  self.testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(self.testedView.exists);
  [self.testedView resolve];
}

- (void)testDescendantsMatchingType
{
  NSSet<NSString *> *expectedLabels = [NSSet setWithArray:@[
    @"Alerts",
    @"Attributes",
    @"Scrolling",
    @"Deadlock app",
  ]];
  NSArray<XCElementSnapshot *> *matchingSnapshots = [self.testedView.lastSnapshot fb_descendantsMatchingType:XCUIElementTypeButton];
  XCTAssertEqual(matchingSnapshots.count, expectedLabels.count);
  NSArray<NSString *> *labels = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.label"];
  XCTAssertEqualObjects([NSSet setWithArray:labels], expectedLabels);

  NSArray<NSNumber *> *types = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.elementType"];
  XCTAssertEqual(types.count, 1, @"matchingSnapshots should contain only one type");
  XCTAssertEqualObjects(types.lastObject, @(XCUIElementTypeButton), @"matchingSnapshots should contain only one type");
}

- (void)testDescendantsMatchingXPath
{
  NSArray<XCElementSnapshot *> *matchingSnapshots = [self.testedView.lastSnapshot fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton[@label='Alerts']"];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testParentMatchingType
{
  XCUIElement *button = self.testedApplication.buttons[@"Alerts"];
  XCTAssertTrue(button.exists);
  [button resolve];
  XCElementSnapshot *windowSnapshot = [button.lastSnapshot fb_parentMatchingType:XCUIElementTypeWindow];
  XCTAssertNotNil(windowSnapshot);
  XCTAssertEqual(windowSnapshot.elementType, XCUIElementTypeWindow);
}

- (void)testParentMatchingOneOfTypes
{
  [self goToAttributesPage];
  XCUIElement *todayPickerWheel = self.testedApplication.pickerWheels[@"Today"];
  XCTAssertTrue(todayPickerWheel.exists);
  [todayPickerWheel resolve];
  XCElementSnapshot *datePicker = [todayPickerWheel.lastSnapshot fb_parentMatchingOneOfTypes:@[@(XCUIElementTypeDatePicker), @(XCUIElementTypeWindow)]];
  XCTAssertNotNil(datePicker);
  XCTAssertEqual(datePicker.elementType, XCUIElementTypeDatePicker);
}

- (void)testParentMatchingOneOfTypesWithXCUIElementTypeAny
{
  [self goToAttributesPage];
  XCUIElement *todayPickerWheel = self.testedApplication.pickerWheels[@"Today"];
  XCTAssertTrue(todayPickerWheel.exists);
  [todayPickerWheel resolve];
  XCElementSnapshot *otherSnapshot = [todayPickerWheel.lastSnapshot fb_parentMatchingOneOfTypes:@[@(XCUIElementTypeAny), @(XCUIElementTypeWindow)]];
  XCTAssertNotNil(otherSnapshot);
  XCTAssertEqual(otherSnapshot.elementType, XCUIElementTypeOther);
}

- (void)testParentMatchingOneOfTypesWithAbsentParents
{
  [self goToAttributesPage];
  XCUIElement *todayPickerWheel = self.testedApplication.pickerWheels[@"Today"];
  XCTAssertTrue(todayPickerWheel.exists);
  [todayPickerWheel resolve];
  XCElementSnapshot *otherSnapshot = [todayPickerWheel.lastSnapshot fb_parentMatchingOneOfTypes:@[@(XCUIElementTypeTab), @(XCUIElementTypeLink)]];
  XCTAssertNil(otherSnapshot);
}

- (void)testParentMatchingOneOfTypesWithFilter
{
  [self goToScrollPageWithCells:false];
  XCUIElement *threeStaticText = self.testedApplication.staticTexts[@"3"];
  [threeStaticText resolve];
  NSArray *acceptedParents = @[
                               @(XCUIElementTypeScrollView),
                               @(XCUIElementTypeCollectionView),
                               @(XCUIElementTypeTable),
                               ];
  XCElementSnapshot *scrollView = [threeStaticText.lastSnapshot fb_parentMatchingOneOfTypes:acceptedParents
    filter:^(XCElementSnapshot *snapshot) {
        return [snapshot isWDVisible];
     }];
  XCTAssertEqualObjects(scrollView.identifier, @"scrollView");
}

- (void)testParentMatchingOneOfTypesWithFilterRetruningNo
{
  [self goToScrollPageWithCells:false];
  XCUIElement *threeStaticText = self.testedApplication.staticTexts[@"3"];
  [threeStaticText resolve];
  NSArray *acceptedParents = @[
                               @(XCUIElementTypeScrollView),
                               @(XCUIElementTypeCollectionView),
                               @(XCUIElementTypeTable),
                               ];
  XCElementSnapshot *scrollView = [threeStaticText.lastSnapshot fb_parentMatchingOneOfTypes:acceptedParents
    filter:^(XCElementSnapshot *snapshot) {
        return NO;
    }];
  XCTAssertNil(scrollView);
}

- (void)testDescendantsCellSnapshots
{
  [self goToScrollPageWithCells:false];
  XCUIElement *scrollView = self.testedApplication.scrollViews[@"scrollView"];
  [scrollView resolve];
  FBAssertWaitTillBecomesTrue(self.testedApplication.staticTexts[@"3"].fb_isVisible);
  NSArray *cells = [scrollView.lastSnapshot fb_descendantsCellSnapshots];
  XCTAssertGreaterThanOrEqual(cells.count, 10);
  XCElementSnapshot *element = cells.firstObject;
  XCTAssertEqualObjects(element.label, @"0");
}

- (void)testParentCellSnapshot
{
  [self goToScrollPageWithCells:true];
  FBAssertWaitTillBecomesTrue(self.testedApplication.staticTexts[@"3"].fb_isVisible);
  XCUIElement *threeStaticText = self.testedApplication.staticTexts[@"3"];
  [threeStaticText resolve];
  XCElementSnapshot *xcuiElementCell = [threeStaticText.lastSnapshot fb_parentCellSnapshot];
  XCTAssertEqual(xcuiElementCell.elementType, 75);
}

@end
