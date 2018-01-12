/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBXPath.h"
#import "FBXPath-Private.h"
#import "XCUIElementDouble.h"

@interface FBXPathTests : XCTestCase
@end

@implementation FBXPathTests

- (NSString *)xmlStringWithElement:(id<FBElement>)element xpathQuery:(nullable NSString *)query
{
  xmlDocPtr doc;
  
  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  int buffersize;
  xmlChar *xmlbuff;
  int rc = [FBXPath xmlRepresentationWithRootElement:(XCElementSnapshot *)element writer:writer elementStore:elementStore query:query];
  if (0 == rc) {
    xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  }
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  
  XCTAssertEqual(rc, 0);
  XCTAssertEqual(1, [elementStore count]);

  return [NSString stringWithCString:(const char *)xmlbuff encoding:NSUTF8StringEncoding];
}

- (void)testDefaultXPathPresentation
{
  XCUIElementDouble *element = [XCUIElementDouble new];
  NSString *resultXml = [self xmlStringWithElement:element xpathQuery:nil];
  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@ type=\"%@\" value=\"%@\" name=\"%@\" label=\"%@\" enabled=\"%@\" visible=\"%@\" x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\" private_indexPath=\"top\"/>\n", element.wdType, element.wdType, element.wdValue, element.wdName, element.wdLabel,  element.wdEnabled ? @"true" : @"false", element.wdVisible ? @"true" : @"false", element.wdRect[@"x"], element.wdRect[@"y"], element.wdRect[@"width"], element.wdRect[@"height"]];
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
}

- (void)testXPathPresentationBasedOnQueryMatchingAllAttributes
{
  XCUIElementDouble *element = [XCUIElementDouble new];
  NSString *resultXml = [self xmlStringWithElement:element xpathQuery:[NSString stringWithFormat:@"//%@[@*]", element.wdType]];
  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@ type=\"%@\" value=\"%@\" name=\"%@\" label=\"%@\" enabled=\"%@\" visible=\"%@\" x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\" private_indexPath=\"top\"/>\n", element.wdType, element.wdType, element.wdValue, element.wdName, element.wdLabel,  element.wdEnabled ? @"true" : @"false", element.wdVisible ? @"true" : @"false", element.wdRect[@"x"], element.wdRect[@"y"], element.wdRect[@"width"], element.wdRect[@"height"]];
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
}

- (void)testXPathPresentationBasedOnQueryMatchingSomeAttributes
{
  XCUIElementDouble *element = [XCUIElementDouble new];
  NSString *resultXml = [self xmlStringWithElement:element xpathQuery:[NSString stringWithFormat:@"//%@[@%@ and contains(@%@, 'blabla')]", element.wdType, @"value", @"name"]];
  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@ value=\"%@\" name=\"%@\" private_indexPath=\"top\"/>\n", element.wdType, element.wdValue, element.wdName];
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
}

- (void)testSnapshotXPathResultsMatching
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCUIElementDouble *root = [XCUIElementDouble new];
  NSString *query = [NSString stringWithFormat:@"//%@", root.wdType];
  int rc = [FBXPath xmlRepresentationWithRootElement:(XCElementSnapshot *)root writer:writer elementStore:elementStore query:query];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertEqual(rc, 0);
  }

  xmlXPathObjectPtr queryResult = [FBXPath evaluate:query document:doc];
  if (NULL == queryResult) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertNotEqual(NULL, queryResult);
  }

  NSArray *matchingSnapshots = [FBXPath collectMatchingSnapshots:queryResult->nodesetval elementStore:elementStore];
  xmlXPathFreeObject(queryResult);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);

  XCTAssertNotNil(matchingSnapshots);
  XCTAssertEqual(1, [matchingSnapshots count]);
}

@end
