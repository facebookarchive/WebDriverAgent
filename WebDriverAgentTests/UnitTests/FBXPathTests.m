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

- (void)testInternalSnapshotXPathPresentation
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCUIElementDouble *root = [XCUIElementDouble new];
  int buffersize;
  xmlChar *xmlbuff;
  int rc = [FBXPath getSnapshotAsXML:(XCElementSnapshot *)root writer:writer elementStore:elementStore];
  if (0 == rc) {
    xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  }
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);

  XCTAssertEqual(rc, 0);

  NSString *resultXml = [NSString stringWithCString:(const char *)xmlbuff encoding:NSUTF8StringEncoding];
  NSString *expectedXml = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<XCUIElementTypeOther type=\"XCUIElementTypeOther\" value=\"magicValue\" name=\"testName\" label=\"testLabel\" enabled=\"true\" visible=\"true\" x=\"0\" y=\"0\" width=\"0\" height=\"0\" private_indexPath=\"top\"/>\n";
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
  XCTAssertEqual(1, [elementStore count]);
}

- (void)testSnapshotXPathResultsMatching
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCUIElementDouble *root = [XCUIElementDouble new];
  int rc = [FBXPath getSnapshotAsXML:(XCElementSnapshot *)root writer:writer elementStore:elementStore];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertEqual(rc, 0);
  }

  xmlXPathObjectPtr queryResult = [FBXPath evaluate:@"//XCUIElementTypeOther" document:doc];
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
