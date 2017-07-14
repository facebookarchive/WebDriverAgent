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
#import "XCElementSnapshotDouble.h"

@interface FBXPathTests : XCTestCase
@end

@implementation FBXPathTests

- (void)testInternalSnapshotXPathPresentation
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCElementSnapshotDouble *root = [XCElementSnapshotDouble new];
  int buffersize;
  xmlChar *xmlbuff;
  int rc = [FBXPath xmlRepresentationWithElement:root writer:writer elementStore:elementStore];
  if (0 == rc) {
    xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  }
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);

  XCTAssertEqual(rc, 0);

  NSString *resultXml = [NSString stringWithCString:(const char *)xmlbuff encoding:NSUTF8StringEncoding];
  NSString *expectedXml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<%@ type=\"%@\" value=\"%@\" name=\"%@\" label=\"%@\" enabled=\"%@\" visible=\"%@\" x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\" uid=\"%@\"/>\n", root.wdType, root.wdType, root.wdValue, root.wdName,
                           root.wdLabel, root.wdEnabled ? @"true" : @"false", root.wdVisible ? @"true" : @"false", [root.wdRect objectForKey:@"x"], [root.wdRect objectForKey:@"y"],
                           [root.wdRect objectForKey:@"width"], [root.wdRect objectForKey:@"height"], @(root.wdUID)];
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
  XCTAssertEqual(1, [elementStore count]);
}

- (void)testSnapshotXPathResultsMatching
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCElementSnapshotDouble *root = [XCElementSnapshotDouble new];
  int rc = [FBXPath xmlRepresentationWithElement:root writer:writer elementStore:elementStore];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertEqual(rc, 0);
  }

  xmlXPathObjectPtr queryResult = [FBXPath evaluateXPathWithQuery:@"//XCUIElementTypeOther" document:doc];
  if (NULL == queryResult) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertNotEqual(NULL, queryResult);
  }

  NSArray *matchingElements = [FBXPath collectMatchingElements:queryResult->nodesetval elementStore:elementStore];
  xmlXPathFreeObject(queryResult);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);

  XCTAssertNotNil(matchingElements);
  XCTAssertEqual(1, [matchingElements count]);
}

@end
