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
#import "XCElementSnapshot+Helpers.h"
#import "XCUIElement.h"

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
    @"Contacts",
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

@end
