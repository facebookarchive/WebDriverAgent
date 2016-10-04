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
#import "XCTestElementSnapshot.h"

@interface FBXPathTests : XCTestCase
@end

@implementation FBXPathTests

- (void)testSnapshotXPathPresentation
{
  int rc;
  xmlTextWriterPtr writer;
  xmlDocPtr doc;
  int buffersize;
  xmlChar *xmlbuff;
  
  writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCTestElementSnapshot *root = [XCTestElementSnapshot new];
  rc = [FBXPath getSnapshotAsXML:root withWriter:writer withElementStore:elementStore];
  if (0 == rc) {
    xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  }
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);

  XCTAssertEqual(rc, 0);

  NSString *resultXml = [NSString stringWithCString:(const char*)xmlbuff encoding:NSUTF8StringEncoding];
  NSString *expectedXml = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<XCUIElementTypeOther type=\"XCUIElementTypeOther\" value=\"кирилиця\" name=\"testName\" label=\"testLabel\" isVisible=\"1\" isEnabled=\"1\" private_indexPath=\"top\"/>\n";
  XCTAssertTrue([resultXml isEqualToString: expectedXml]);
  XCTAssertEqual(1, [elementStore count]);
}

- (void)testSnapshotXPathResultsMatching
{
  int rc;
  xmlTextWriterPtr writer;
  xmlDocPtr doc;
  
  writer = xmlNewTextWriterDoc(&doc, 0);
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  XCTestElementSnapshot *root = [XCTestElementSnapshot new];
  rc = [FBXPath getSnapshotAsXML:root withWriter:writer withElementStore:elementStore];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertEqual(rc, 0);
  }
  
  xmlXPathObjectPtr queryResult = [FBXPath evaluate:@"//XCUIElementTypeOther" withDocument:doc];
  if (NULL == queryResult) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    XCTAssertNotEqual(NULL, queryResult);
  }
  
  NSArray *matchingSnapshots = [FBXPath collectMatchingSnapshots:queryResult->nodesetval withElementStore:elementStore];
  xmlXPathFreeObject(queryResult);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);

  XCTAssertNotNil(matchingSnapshots);
  XCTAssertEqual(1, [matchingSnapshots count]);
}

@end