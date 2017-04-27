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
#import "XCUIElement+FBUtilities.h"
#import "FBXPath.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@interface FBXPathIntegrationTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *testedView;
@end

@implementation FBXPathIntegrationTests

- (void)setUp
{
  [super setUp];
  self.testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(self.testedView.exists);
  [self.testedView resolve];
}

- (void)testSingleDescendantXMLRepresentation
{
  NSString *expectedType = @"XCUIElementTypeButton";
  XCUIElement *matchingElement = [[self.testedView fb_descendantsMatchingXPathQuery:[NSString stringWithFormat:@"//%@", expectedType] shouldReturnAfterFirstMatch:YES] firstObject];
  XCElementSnapshot *matchingSnapshot = matchingElement.fb_lastSnapshot;

  NSString *xmlStr = [FBXPath xmlStringWithSnapshot:matchingSnapshot];
  XCTAssertNotNil(xmlStr);

  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@ type=\"%@\" name=\"%@\" label=\"%@\" enabled=\"%@\" visible=\"%@\" x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\"/>\n", expectedType, expectedType, matchingSnapshot.wdName, matchingSnapshot.wdLabel, matchingSnapshot.wdEnabled ? @"true" : @"false", matchingSnapshot.wdVisible ? @"true" : @"false", [matchingSnapshot.wdRect[@"x"] stringValue], [matchingSnapshot.wdRect[@"y"] stringValue], [matchingSnapshot.wdRect[@"width"] stringValue], [matchingSnapshot.wdRect[@"height"] stringValue]];
  XCTAssertTrue([xmlStr isEqualToString: expectedXml]);
}

- (void)testFindMatchesInElement
{
  NSArray *matchingSnapshots = [FBXPath findMatchesIn:self.testedView.fb_lastSnapshot xpathQuery:@"//XCUIElementTypeButton"];
  XCTAssertEqual([matchingSnapshots count], 4);
  for (id<FBElement> element in matchingSnapshots) {
    XCTAssertTrue([element.wdType isEqualToString:@"XCUIElementTypeButton"]);
  }
}

- (void)testFindMatchesInElementWithDotNotation
{
  NSArray *matchingSnapshots = [FBXPath findMatchesIn:self.testedView.fb_lastSnapshot xpathQuery:@".//XCUIElementTypeButton"];
  XCTAssertEqual([matchingSnapshots count], 4);
  for (id<FBElement> element in matchingSnapshots) {
    XCTAssertTrue([element.wdType isEqualToString:@"XCUIElementTypeButton"]);
  }
}

@end
