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
#import "XCUIElement.h"
#import "XCUIElement+FBFind.h"
#import "XCElementSnapshot+FBHelpers.h"

@interface XCUIElementFBFindTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *testedView;
@end

@implementation XCUIElementFBFindTests

- (void)setUp
{
  [super setUp];
  self.testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(self.testedView.exists);
  [self.testedView resolve];
}

- (void)testDescendantsWithClassName
{
  NSSet<NSString *> *expectedLabels = [NSSet setWithArray:@[
    @"Alerts",
    @"Attributes",
    @"Scrolling",
    @"Deadlock app",
  ]];
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingClassName:@"XCUIElementTypeButton"];
  XCTAssertEqual(matchingSnapshots.count, expectedLabels.count);
  NSArray<NSString *> *labels = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.label"];
  XCTAssertEqualObjects([NSSet setWithArray:labels], expectedLabels);

  NSArray<NSNumber *> *types = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.elementType"];
  XCTAssertEqual(types.count, 1, @"matchingSnapshots should contain only one type");
  XCTAssertEqualObjects(types.lastObject, @(XCUIElementTypeButton), @"matchingSnapshots should contain only one type");
}

- (void)testDescendantsWithIdentifier
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingIdentifier:@"Alerts"];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton[@label='Alerts']"];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithComplexXPathQuery
{
    NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingXPathQuery:@"//*[@label='Scrolling']/preceding::*[boolean(string(@label))]"];
    XCTAssertEqual(matchingSnapshots.count, 3);
}

- (void)testDescendantsWithWrongXPathQuery
{
    XCTAssertThrowsSpecificNamed([self.testedView fb_descendantsMatchingXPathQuery:@"//*[blabla(@label, Scrolling')]"], NSException,
                                 XCElementSnapshotInvalidXPathException);
}

- (void)testDescendantsWithPredicateString
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label = 'Alerts'"];
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingPredicate:predicate];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithPropertyStrict
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingProperty:@"label" value:@"Alert" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 0);
  matchingSnapshots = [self.testedView fb_descendantsMatchingProperty:@"label" value:@"Alerts" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithPropertyPartial
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingProperty:@"label" value:@"Alerts" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

@end
