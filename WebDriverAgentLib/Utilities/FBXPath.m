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
#import "XCUIElement+FBUtilities.h"
#import "NSString+FBXMLSafeString.h"

const static char *_UTF8Encoding = "UTF-8";
static xmlChar *const kXMLIndexPathKey = BAD_CAST "uid";

NSString *const XCElementSnapshotInvalidXPathException = @"XCElementSnapshotInvalidXPathException";
NSString *const XCElementSnapshotXPathQueryEvaluationException = @"XCElementSnapshotXPathQueryEvaluationException";

@implementation FBXPath

+ (void)throwException:(NSString *)name forQuery:(NSString *)xpathQuery __attribute__((noreturn))
{
  NSString *reason = [NSString stringWithFormat:@"Cannot evaluate results for XPath expression \"%@\"", xpathQuery];
  @throw [NSException exceptionWithName:name reason:reason userInfo:@{}];
}

+ (nullable NSString *)xmlStringWithElement:(id<FBElement>)root
{
  xmlDocPtr doc;
  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  int rc = [self.class xmlRepresentationWithElement:root writer:writer elementStore:nil];
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

+ (NSArray<id<FBElement>> *)findMatchesIn:(id<FBElement>)root xpathQuery:(NSString *)xpathQuery
{
  xmlDocPtr doc;

  xmlTextWriterPtr writer = xmlNewTextWriterDoc(&doc, 0);
  if (NULL == writer) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlNewTextWriterDoc for XPath query \"%@\"", xpathQuery];
    [FBXPath throwException:XCElementSnapshotXPathQueryEvaluationException forQuery:xpathQuery];
    return nil;
  }
  NSMutableDictionary<NSString *, id<FBElement>> *elementStore = [NSMutableDictionary dictionary];
  int rc = [self.class xmlRepresentationWithElement:root writer:writer elementStore:elementStore];
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

  NSArray<id<FBElement>> *result = [self.class collectMatchingElements:queryResult->nodesetval elementStore:elementStore];
  xmlXPathFreeObject(queryResult);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
  if (nil == result) {
    [FBXPath throwException:XCElementSnapshotXPathQueryEvaluationException forQuery:xpathQuery];
    return nil;
  }
  return result;
}

+ (NSArray<id<FBElement>> *)collectMatchingElements:(xmlNodeSetPtr)nodeSet elementStore:(NSDictionary<NSString *, id<FBElement>> *)elementStore
{
  if (xmlXPathNodeSetIsEmpty(nodeSet)) {
    return @[];
  }
  NSMutableArray<id<FBElement>> *result = [NSMutableArray array];
  for (NSInteger i = 0; i < nodeSet->nodeNr; i++) {
    xmlNodePtr currentNode = nodeSet->nodeTab[i];
    xmlChar *attrValue = xmlGetProp(currentNode, kXMLIndexPathKey);
    if (NULL == attrValue) {
      [FBLogger log:@"Failed to invoke libxml2>xmlGetProp"];
      return nil;
    }
    id<FBElement> element = [elementStore objectForKey:(id)[NSString stringWithCString:(const char *)attrValue encoding:NSUTF8StringEncoding]];
    if (element) {
      [result addObject:element];
    }
  }
  return result.copy;
}

+ (int)xmlRepresentationWithElement:(id<FBElement>)root writer:(xmlTextWriterPtr)writer elementStore:(nullable NSDictionary<NSString *, id<FBElement>> *)elementStore
{
  int rc = xmlTextWriterStartDocument(writer, NULL, _UTF8Encoding, NULL);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartDocument. Error code: %d", rc];
    return rc;
  }
  if ([root isKindOfClass:XCElementSnapshot.class]) {
    rc = [self.class recursiveXMLRepresentationWithSnapshot:(XCElementSnapshot *)root elementStore:elementStore writer:writer];
  } else {
    NSArray<XCUIElement *> *elementsTree = [(XCUIElement *)root descendantsMatchingType:XCUIElementTypeAny].allElementsBoundByIndex;
    rc = [self.class recursiveXMLRepresentationWithElement:(XCUIElement *)root elementsTree:elementsTree elementStore:elementStore writer:writer];
  }
  if (rc < 0) {
    [FBLogger log:@"Failed to generate XML presentation of a screen element"];
    return rc;
  }
  if (elementStore) {
    // The current node should be in the store as well
    [elementStore setValue:root forKey:[NSString stringWithFormat:@"%@", @(root.wdUID)]];
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

+ (int)recordElementAttributes:(xmlTextWriterPtr)writer forElement:(id<FBElement>)element includeIndex:(BOOL)includeIndex
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
  
  if (includeIndex) {
    rc = xmlTextWriterWriteAttribute(writer, kXMLIndexPathKey, [self.class safeXmlStringWithString:[NSString stringWithFormat:@"%@", @(element.wdUID)]]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(wdUID='%@'). Error code: %d", @(element.wdUID), rc];
      return rc;
    }
  }
  
  return 0;
}

+ (int)recursiveXMLRepresentationWithSnapshot:(XCElementSnapshot *)root elementStore:(nullable NSDictionary<NSString *, id<FBElement>> *)elementStore writer:(xmlTextWriterPtr)writer
{
  int rc = xmlTextWriterStartElement(writer, [FBXPath xmlCharPtrForInput:[root.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement. Error code: %d", rc];
    return rc;
  }

  rc = [FBXPath recordElementAttributes:writer forElement:root includeIndex:elementStore != nil];
  if (rc < 0) {
    return rc;
  }
  
  for (XCElementSnapshot *child in root.children) {
    if (elementStore) {
      [elementStore setValue:child forKey:[NSString stringWithFormat:@"%@", @(child.wdUID)]];
    }
    rc = [self recursiveXMLRepresentationWithSnapshot:child elementStore:elementStore writer:writer];
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

+ (int)recursiveXMLRepresentationWithElement:(XCUIElement *)root elementsTree:(NSArray<XCUIElement *> *)elementsTree elementStore:(nullable NSDictionary<NSString *, id<FBElement>> *)elementStore writer:(xmlTextWriterPtr)writer
{
  int rc = xmlTextWriterStartElement(writer, [FBXPath xmlCharPtrForInput:[root.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement. Error code: %d", rc];
    return rc;
  }
  
  rc = [FBXPath recordElementAttributes:writer forElement:root includeIndex:elementStore != nil];
  if (rc < 0) {
    return rc;
  }
  
  NSMutableArray<XCUIElement *> *remainingTreeNodes = elementsTree.mutableCopy;
  NSMutableArray<XCUIElement *> *children = [NSMutableArray array];
  NSUInteger rootUID = root.wdUID;
  for (XCUIElement *node in elementsTree) {
    XCElementSnapshot *nodeSnapshot = node.fb_lastSnapshot;
    if (nodeSnapshot.parent && nodeSnapshot.parent.wdUID == rootUID) {
      [children addObject:node];
      [remainingTreeNodes removeObject:node];
    }
  }
  for (XCUIElement *child in children) {
    if (elementStore) {
      [elementStore setValue:child forKey:[NSString stringWithFormat:@"%@", @(child.wdUID)]];
    }
    rc = [self recursiveXMLRepresentationWithElement:child elementsTree:remainingTreeNodes.copy elementStore:elementStore writer:writer];
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

+ (int)getElementAsXML:(XCUIElement *)root writer:(xmlTextWriterPtr)writer
{
  return 0;
}

@end
