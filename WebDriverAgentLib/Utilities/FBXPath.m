/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXPath.h"

#import "FBLogger.h"
#import "XCAXClient_iOS.h"
#import "XCTestDriver.h"
#import "XCTestPrivateSymbols.h"
#import "XCUIElement.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "NSString+FBXMLSafeString.h"

const static char *_UTF8Encoding = "UTF-8";

static NSString *const kXMLIndexPathKey = @"private_indexPath";
static NSString *const topNodeIndexPath = @"top";
NSString *const XCElementSnapshotInvalidXPathException = @"XCElementSnapshotInvalidXPathException";
NSString *const XCElementSnapshotXPathQueryEvaluationException = @"XCElementSnapshotXPathQueryEvaluationException";

@implementation FBXPath

+ (void)throwException:(NSString *)name forQuery:(NSString *)xpathQuery __attribute__((noreturn))
{
  NSString *reason = [NSString stringWithFormat:@"Cannot evaluate results for XPath expression \"%@\"", xpathQuery];
  @throw [NSException exceptionWithName:name reason:reason userInfo:@{}];
}

+ (nullable NSString *)xmlStringWithSnapshot:(XCElementSnapshot *)root
{
  xmlDocPtr doc;
  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  int rc = [FBXPath getSnapshotAsXML:(XCElementSnapshot *)root writer:writer elementStore:nil];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return nil;
  }
  int buffersize;
  xmlChar *xmlbuff;
  xmlDocDumpFormatMemory(doc, &xmlbuff, &buffersize, 1);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  return [NSString stringWithCString:(const char *)xmlbuff encoding:NSUTF8StringEncoding];
}

+ (NSArray<XCElementSnapshot *> *)findMatchesIn:(XCElementSnapshot *)root xpathQuery:(NSString *)xpathQuery
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  if (NULL == writer) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlNewTextWriterDoc for XPath query \"%@\"", xpathQuery];
    [FBXPath throwException:XCElementSnapshotXPathQueryEvaluationException forQuery:xpathQuery];
    return nil;
  }
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  int rc = [FBXPath getSnapshotAsXML:root writer:writer elementStore:elementStore];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    [FBXPath throwException:XCElementSnapshotXPathQueryEvaluationException forQuery:xpathQuery];
    return nil;
  }

  xmlXPathObjectPtr queryResult = [FBXPath evaluate:xpathQuery document:doc];
  if (NULL == queryResult) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    [FBXPath throwException:XCElementSnapshotInvalidXPathException forQuery:xpathQuery];
    return nil;
  }

  NSArray *matchingSnapshots = [FBXPath collectMatchingSnapshots:queryResult->nodesetval elementStore:elementStore];
  xmlXPathFreeObject(queryResult);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  if (nil == matchingSnapshots) {
    [FBXPath throwException:XCElementSnapshotXPathQueryEvaluationException forQuery:xpathQuery];
    return nil;
  }
  return matchingSnapshots;
}

+ (NSArray *)collectMatchingSnapshots:(xmlNodeSetPtr)nodeSet elementStore:(NSMutableDictionary *)elementStore
{
  if (xmlXPathNodeSetIsEmpty(nodeSet)) {
    return @[];
  }
  NSMutableArray *matchingSnapshots = [NSMutableArray array];
  const xmlChar *indexPathKeyName = [FBXPath xmlCharPtrForInput:[kXMLIndexPathKey cStringUsingEncoding:NSUTF8StringEncoding]];
  for (NSInteger i = 0; i < nodeSet->nodeNr; i++) {
    xmlNodePtr currentNode = nodeSet->nodeTab[i];
    xmlChar *attrValue = xmlGetProp(currentNode, indexPathKeyName);
    if (NULL == attrValue) {
      [FBLogger log:@"Failed to invoke libxml2>xmlGetProp"];
      return nil;
    }
    XCElementSnapshot *element = [elementStore objectForKey:(id)[NSString stringWithCString:(const char *)attrValue encoding:NSUTF8StringEncoding]];
    if (element) {
      [matchingSnapshots addObject:element];
    }
  }
  return matchingSnapshots;
}

+ (int)getSnapshotAsXML:(XCElementSnapshot *)root writer:(xmlTextWriterPtr)writer elementStore:(nullable NSMutableDictionary *)elementStore
{
  int rc = xmlTextWriterStartDocument(writer, NULL, _UTF8Encoding, NULL);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartDocument. Error code: %d", rc];
    return rc;
  }
  rc = [FBXPath generateXMLPresentation:root indexPath:(elementStore != nil ? topNodeIndexPath : nil) elementStore:elementStore writer:writer];
  if (rc < 0) {
    [FBLogger log:@"Failed to generate XML presentation of a screen element"];
    return rc;
  }
  if (nil != elementStore) {
    // The current node should be in the store as well
    elementStore[topNodeIndexPath] = root;
  }
  rc = xmlTextWriterEndDocument(writer);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlXPathNewContext. Error code: %d", rc];
    return rc;
  }
  return 0;
}

+ (xmlChar *)xmlCharPtrForInput:(const char *)input
{
  if (0 == input) {
    return NULL;
  }

  xmlCharEncodingHandlerPtr handler = xmlFindCharEncodingHandler(_UTF8Encoding);
  if (!handler) {
    [FBLogger log:@"Failed to invoke libxml2>xmlFindCharEncodingHandler"];
    return NULL;
  }

  int size = (int) strlen(input) + 1;
  int outputSize = size * 2 - 1;
  xmlChar *output = (unsigned char *) xmlMalloc((size_t) outputSize);

  if (0 != output) {
    int temp = size - 1;
    int ret = handler->input(output, &outputSize, (const xmlChar *) input, &temp);
    if ((ret < 0) || (temp - size + 1)) {
      xmlFree(output);
      output = 0;
    } else {
      output = (unsigned char *) xmlRealloc(output, outputSize + 1);
      output[outputSize] = 0;
    }
  }

  return output;
}

+ (xmlXPathObjectPtr)evaluate:(NSString *)xpathQuery document:(xmlDocPtr)doc
{
  xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
  if (NULL == xpathCtx) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlXPathNewContext for XPath query \"%@\"", xpathQuery];
    return NULL;
  }
  xpathCtx->node = doc->children;

  xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression([FBXPath xmlCharPtrForInput:[xpathQuery cStringUsingEncoding:NSUTF8StringEncoding]], xpathCtx);
  if (NULL == xpathObj) {
    xmlXPathFreeContext(xpathCtx);
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlXPathEvalExpression for XPath query \"%@\"", xpathQuery];
    return NULL;
  }
  xmlXPathFreeContext(xpathCtx);
  return xpathObj;
}

+ (xmlChar *)safeXmlStringWithString:(NSString *)str
{
  if (nil == str) {
    return NULL;
  }
  
  NSString *safeString = [str fb_xmlSafeStringWithReplacement:@""];
  return [self.class xmlCharPtrForInput:[safeString cStringUsingEncoding:NSUTF8StringEncoding]];
}

+ (int)recordElementAttributes:(xmlTextWriterPtr)writer forElement:(XCElementSnapshot *)element indexPath:(nullable NSString *)indexPath
{
  int rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "type", [self.class safeXmlStringWithString:element.wdType]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(type='%@'). Error code: %d", element.wdType, rc];
    return rc;
  }
  if (element.wdValue) {
    id value = element.wdValue;
    NSString *stringValue;
    if ([value isKindOfClass:[NSValue class]]) {
      stringValue = [value stringValue];
    } else if ([value isKindOfClass:[NSString class]]) {
      stringValue = value;
    } else {
      stringValue = [value description];
    }
    rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "value", [self.class safeXmlStringWithString:stringValue]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(value='%@'). Error code: %d", stringValue, rc];
      return rc;
    }
  }
  if (element.wdName) {
    rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "name", [self.class safeXmlStringWithString:element.wdName]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(name='%@'). Error code: %d", element.wdName, rc];
      return rc;
    }
  }
  if (element.wdLabel) {
    rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "label", [self.class safeXmlStringWithString:element.wdLabel]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(label='%@'). Error code: %d", element.wdLabel, rc];
      return rc;
    }
  }
  rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "enabled", element.wdEnabled ? BAD_CAST "true" : BAD_CAST "false");
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(wdEnabled). Error code: %d", rc];
    return rc;
  }
  rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "visible", element.wdVisible ? BAD_CAST "true" : BAD_CAST "false");
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(wdVisible). Error code: %d", rc];
    return rc;
  }
  for (NSString *attrName in @[@"x", @"y", @"width", @"height"]) {
    rc = xmlTextWriterWriteAttribute(writer, [self.class safeXmlStringWithString:attrName],
                                     [self.class safeXmlStringWithString:[element.wdRect[attrName] stringValue]]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(%@). Error code: %d", attrName, rc];
      return rc;
    }
  }

  if (nil != indexPath) {
    rc = xmlTextWriterWriteAttribute(writer, [self.class safeXmlStringWithString:kXMLIndexPathKey], [self.class safeXmlStringWithString:indexPath]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(indexPath='%@'). Error code: %d", indexPath, rc];
      return rc;
    }
  }

  return 0;
}

+ (int)generateXMLPresentation:(XCElementSnapshot *)root indexPath:(nullable NSString *)indexPath elementStore:(nullable NSMutableDictionary *)elementStore writer:(xmlTextWriterPtr)writer
{
  NSAssert((indexPath == nil && elementStore == nil) || (indexPath != nil && elementStore != nil), @"Either both or none of indexPath and elementStore arguments should be equal to nil", nil);

  int rc = xmlTextWriterStartElement(writer, [FBXPath xmlCharPtrForInput:[root.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement. Error code: %d", rc];
    return rc;
  }

  rc = [FBXPath recordElementAttributes:writer forElement:root indexPath:indexPath];
  if (rc < 0) {
    return rc;
  }

  NSArray *children = root.children;
  for (NSUInteger i = 0; i < [children count]; i++) {
    XCElementSnapshot *childSnapshot = children[i];
    NSString *newIndexPath = (indexPath != nil) ? [indexPath stringByAppendingFormat:@",%lu", (unsigned long)i] : nil;
    if (nil != elementStore) {
      elementStore[newIndexPath] = childSnapshot;
    }
    rc = [self generateXMLPresentation:childSnapshot indexPath:newIndexPath elementStore:elementStore writer:writer];
    if (rc < 0) {
      return rc;
    }
  }

  rc = xmlTextWriterEndElement(writer);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterEndElement. Error code: %d", rc];
    return rc;
  }
  return 0;
}

@end
