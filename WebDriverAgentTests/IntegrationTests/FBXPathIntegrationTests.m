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
#import "FBMacros.h"
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
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
  self.testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(self.testedView.exists);
  [self.testedView resolve];
}

- (void)testSingleDescendantXMLRepresentation
{
  NSString *expectedType = @"XCUIElementTypeButton";
  XCUIElement *matchedElement = [[self.testedView fb_descendantsMatchingXPathQuery:[NSString stringWithFormat:@"//%@", expectedType] shouldReturnAfterFirstMatch:YES] firstObject];
  id<FBElement> match = matchedElement;
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    match = matchedElement.fb_lastSnapshot;
  }
  
  NSString *xmlStr = [FBXPath xmlStringWithElement:match];
  XCTAssertNotNil(xmlStr);

  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@ type=\"%@\" name=\"%@\" label=\"%@\" enabled=\"%@\" visible=\"%@\" x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\"/>\n", expectedType, expectedType, match.wdName, match.wdLabel, match.wdEnabled ? @"true" : @"false", match.wdVisible ? @"true" : @"false", [match.wdRect[@"x"] stringValue], [match.wdRect[@"y"] stringValue], [match.wdRect[@"width"] stringValue], [match.wdRect[@"height"] stringValue]];
  XCTAssertTrue([xmlStr isEqualToString: expectedXml]);
}

- (void)testFindMatchesInElement
{
  XCUIElement *matchedElement = self.testedView;
  id<FBElement> match = matchedElement;
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    match = matchedElement.fb_lastSnapshot;
  }
  NSArray *matchingSnapshots = [FBXPath findMatchesIn:match xpathQuery:@"//XCUIElementTypeButton"];
  XCTAssertEqual([matchingSnapshots count], 4);
  for (id<FBElement> element in matchingSnapshots) {
    XCTAssertTrue([element.wdType isEqualToString:@"XCUIElementTypeButton"]);
  }
}

- (void)testFindMatchesInElementWithDotNotation
{
  XCUIElement *matchedElement = self.testedView;
  id<FBElement> match = matchedElement;
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    match = matchedElement.fb_lastSnapshot;
  }
  NSArray *matchingSnapshots = [FBXPath findMatchesIn:match xpathQuery:@".//XCUIElementTypeButton"];
  XCTAssertEqual([matchingSnapshots count], 4);
  for (id<FBElement> element in matchingSnapshots) {
    XCTAssertTrue([element.wdType isEqualToString:@"XCUIElementTypeButton"]);
  }
}

@end
