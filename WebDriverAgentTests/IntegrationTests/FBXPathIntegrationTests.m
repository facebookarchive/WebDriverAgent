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
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBFind.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBUtilities.h"
#import "FBXPath.h"
#import "FBXPath-Private.h"
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
  XCUIElement *matchingElement = [[self.testedView fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton" shouldReturnAfterFirstMatch:YES] firstObject];
  XCElementSnapshot *matchingSnapshot = matchingElement.fb_lastSnapshot;
  
  xmlDocPtr doc;
  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  int buffersize;
  xmlChar *xmlbuff;
  int rc = [FBXPath getSnapshotAsXML:matchingSnapshot writer:writer elementStore:elementStore];
  if (0 == rc) {
    xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  }
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  XCTAssertEqual(rc, 0);
  
  NSString *resultXml = [NSString stringWithCString:(const char*)xmlbuff encoding:NSUTF8StringEncoding];
  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<XCUIElementTypeButton type=\"XCUIElementTypeButton\" name=\"Alerts\" label=\"Alerts\" visible=\"true\" enabled=\"true\" x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\" private_indexPath=\"top\"/>\n", [matchingSnapshot.wdRect[@"x"] stringValue], [matchingSnapshot.wdRect[@"y"] stringValue], [matchingSnapshot.wdRect[@"width"] stringValue], [matchingSnapshot.wdRect[@"height"] stringValue]];
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
}

- (void)testFindMatchesInElement
{
  NSArray *matchingSnapshots = [FBXPath findMatchesIn:self.testedView.fb_lastSnapshot xpathQuery:@"//XCUIElementTypeButton"];
  
  XCTAssertEqual([matchingSnapshots count], 4);
  for (id<FBElement> element in matchingSnapshots) {
    XCTAssertTrue([element.wdType isEqualToString:@"XCUIElementTypeButton"]);
  }
}


@end
