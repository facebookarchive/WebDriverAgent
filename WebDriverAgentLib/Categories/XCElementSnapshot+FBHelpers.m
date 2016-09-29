/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCElementSnapshot+FBHelpers.h"

#ifdef __clang__
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wpadded"
#endif

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>

#ifdef __clang__
    #pragma clang diagnostic pop
#endif

#import "FBFindElementCommands.h"
#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBXPathCreator.h"
#import "XCAXClient_iOS.h"
#import "XCTestDriver.h"
#import "XCTestPrivateSymbols.h"
#import "XCUIElement.h"
#import "XCUIElement+FBWebDriverAttributes.h"

const static char *_UTF8Encoding = "UTF-8";

static NSString *const kXMLIndexPathKey = @"private_indexPath";

inline static BOOL valuesAreEqual(id value1, id value2);
inline static BOOL isSnapshotTypeAmongstGivenTypes(XCElementSnapshot* snapshot, NSArray<NSNumber *> *types);

@implementation XCElementSnapshot (FBHelpers)

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type
{
  NSString *xpathQuery = [FBXPathCreator xpathWithSubelementsOfType:type];
  return [self fb_descendantsMatchingXPathQuery:xpathQuery];
}

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery
{
  int rc;
  xmlTextWriterPtr writer;
  xmlDocPtr doc;
    
  writer = xmlNewTextWriterDoc(&doc, 0);
  if (NULL == writer) {
    NSLog(@"Failed to invoke libxml2>xmlNewTextWriterDoc");
    return nil;
  }
  rc = xmlTextWriterStartDocument(writer, NULL, _UTF8Encoding, NULL);
  if (rc < 0) {
    NSLog(@"Failed to invoke libxml2>xmlTextWriterStartDocument");
    return nil;
  }
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  rc = [self generateXMLPresentation:self indexPath:@"top" elementStore:elementStore writer:writer];
  if (rc < 0) {
    NSLog(@"Failed to generate XML map of the top element");
    return nil;
  }
  rc = xmlTextWriterEndDocument(writer);
  if (rc < 0) {
    NSLog(@"Failed to invoke libxml2>xmlTextWriterEndDocument");
    return nil;
  }
    
  xmlXPathContextPtr xpathCtx;
  xmlXPathObjectPtr xpathObj;
 
  xpathCtx = xmlXPathNewContext(doc);
  if (NULL == xpathCtx) {
    NSLog(@"Failed to invoke libxml2>xmlXPathNewContext");
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return nil;
  }

  xpathObj = xmlXPathEvalExpression([XCElementSnapshot xmlCharPtrForInput:[xpathQuery cStringUsingEncoding:NSUTF8StringEncoding]], xpathCtx);
  if (NULL == xpathObj) {
    NSLog(@"Failed to invoke libxml2>xmlXPathEvalExpression");
    xmlXPathFreeContext(xpathCtx);
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return nil;
  }
  xmlNodeSetPtr nodes = xpathObj->nodesetval;
  if (!nodes) {
    xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx);
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    return nil;
  }

  NSMutableArray *matchingSnapshots = [NSMutableArray array];
  const xmlChar *indexPathKeyName = [XCElementSnapshot xmlCharPtrForInput:[kXMLIndexPathKey cStringUsingEncoding:NSUTF8StringEncoding]];
  for (NSInteger i = 0; i < nodes->nodeNr; i++) {
    xmlNodePtr currentNode = nodes->nodeTab[i];
    xmlChar *attrValue = xmlGetProp(currentNode, indexPathKeyName);
    if (NULL == attrValue) {
      NSLog(@"Cannot read %@ attribute from a node", kXMLIndexPathKey);
      xmlXPathFreeObject(xpathObj);
      xmlXPathFreeContext(xpathCtx);
      xmlFreeTextWriter(writer);
      xmlFreeDoc(doc);
      return nil;
    }
    XCElementSnapshot *element = [elementStore objectForKey:(id)[NSString stringWithCString:(const char*)attrValue encoding:NSUTF8StringEncoding]];
    if (element) {
      [matchingSnapshots addObject:element];
    }
  }
    
  xmlXPathFreeObject(xpathObj);
  xmlXPathFreeContext(xpathCtx);
  xmlFreeTextWriter(writer);
  xmlFreeDoc(doc);
   
  return matchingSnapshots;
}

+ (xmlChar *) xmlCharPtrForInput:(const char *)input
{
  xmlChar *output;
  int ret;
  int size;
  int outputSize;
  int temp;
  xmlCharEncodingHandlerPtr handler;
  if (0 == input) {
    NSLog(@"xmlCharPtrForInput method expects non-empty input");
    return NULL;
  }
    
  handler = xmlFindCharEncodingHandler(_UTF8Encoding);
  if (!handler) {
    NSLog(@"Failed to invoke libxml2>xmlFindCharEncodingHandler");
    return NULL;
  }
    
  size = (int) strlen(input) + 1;
  outputSize = size * 2 - 1;
  output = (unsigned char *) xmlMalloc((size_t) outputSize);
    
  if (0 != output) {
    temp = size - 1;
    ret = handler->input(output, &outputSize, (const xmlChar *) input, &temp);
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

- (int )generateXMLPresentation:(XCElementSnapshot *)snapshot indexPath:(NSString *)indexPath elementStore:(NSMutableDictionary *)elementStore writer:(xmlTextWriterPtr)writer
{
  int rc;
    
  rc = xmlTextWriterStartElement(writer, [XCElementSnapshot xmlCharPtrForInput:[snapshot.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    NSLog(@"Failed to invoke libxml2>xmlTextWriterStartElement");
    return rc;
  }
    
  rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "type",
                                   [XCElementSnapshot xmlCharPtrForInput:[snapshot.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    NSLog(@"Failed to invoke libxml2>xmlTextWriterWriteAttribute");
    return rc;
  }
    
  if (snapshot.wdValue) {
    id value = snapshot.wdValue;
    NSString *stringValue;
    if ([value isKindOfClass:[NSValue class]]) {
      stringValue = [value stringValue];
    } else if ([value isKindOfClass:[NSString class]]) {
      stringValue = value;
    } else {
      stringValue = [value description];
    }
    rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "value",
                                     [XCElementSnapshot xmlCharPtrForInput:[stringValue cStringUsingEncoding:NSUTF8StringEncoding]]);
    if (rc < 0) {
      NSLog(@"Failed to invoke libxml2>xmlTextWriterWriteAttribute");
      return rc;
    }
  }
    
  if (snapshot.wdName) {
    rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "name",
                                     [XCElementSnapshot xmlCharPtrForInput:[snapshot.wdName cStringUsingEncoding:NSUTF8StringEncoding]]);
    if (rc < 0) {
      NSLog(@"Failed to invoke libxml2>xmlTextWriterWriteAttribute");
      return rc;
    }
  }
  if (snapshot.wdLabel) {
    rc = xmlTextWriterWriteAttribute(writer, BAD_CAST "label",
                                     [XCElementSnapshot xmlCharPtrForInput:[snapshot.wdLabel cStringUsingEncoding:NSUTF8StringEncoding]]);
    if (rc < 0) {
      NSLog(@"Failed to invoke libxml2>xmlTextWriterWriteAttribute");
      return rc;
    }
  }
  rc = xmlTextWriterWriteAttribute(writer, [XCElementSnapshot xmlCharPtrForInput:[kXMLIndexPathKey cStringUsingEncoding:NSUTF8StringEncoding]],
                                   [XCElementSnapshot xmlCharPtrForInput:[indexPath cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    NSLog(@"Failed to invoke libxml2>xmlTextWriterWriteAttribute");
    return rc;
  }
    
  NSArray *children = snapshot.children;
  for (NSUInteger i  = 0; i < [children count]; i++) {
    XCElementSnapshot *childSnapshot = children[i];
    NSString *newIndexPath = [indexPath stringByAppendingFormat:@",%lu", (unsigned long)i];
    elementStore[newIndexPath] = childSnapshot;
    rc = [self generateXMLPresentation:childSnapshot indexPath:newIndexPath elementStore:elementStore writer:writer];
    if (rc < 0) {
      NSLog(@"Failed to generate XML map of a subelement");
      return rc;
    }
  }
    
  rc = xmlTextWriterEndElement(writer);
  if (rc < 0) {
    NSLog(@"Failed to invoke libxml2>xmlTextWriterEndElement");
    return rc;
  }
    
  return 0;
}

- (XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type
{
  NSArray *acceptedParents = @[@(type)];
  return [self fb_parentMatchingOneOfTypes:acceptedParents];
}

- (XCElementSnapshot *)fb_parentMatchingOneOfTypes:(NSArray<NSNumber *> *)types
{
  return [self fb_parentMatchingOneOfTypes:types filter:^(XCElementSnapshot *snapshot) {
    return YES;
  }];
}

- (XCElementSnapshot *)fb_parentMatchingOneOfTypes:(NSArray<NSNumber *> *)types filter:(BOOL(^)(XCElementSnapshot *snapshot))filter
{
  XCElementSnapshot *snapshot = self.parent;
  while (snapshot && !(isSnapshotTypeAmongstGivenTypes(snapshot, types) && filter(snapshot))) {
    snapshot = snapshot.parent;
  }
  return snapshot;
}

- (id)fb_attributeValue:(NSNumber *)attribute
{
  NSDictionary *attributesResult = [[XCAXClient_iOS sharedClient] attributesForElementSnapshot:self attributeList:@[attribute]];
  return (id __nonnull)attributesResult[attribute];
}

- (BOOL)fb_framelessFuzzyMatchesElement:(XCElementSnapshot *)snapshot
{
  return self.elementType == snapshot.elementType &&
    valuesAreEqual(self.identifier, snapshot.identifier) &&
    valuesAreEqual(self.title, snapshot.title) &&
    valuesAreEqual(self.label, snapshot.label) &&
    valuesAreEqual(self.value, snapshot.value) &&
    valuesAreEqual(self.placeholderValue, snapshot.placeholderValue);
}

- (NSArray<XCElementSnapshot *> *)fb_descendantsCellSnapshots
{
  NSArray<XCElementSnapshot *> *cellSnapshots = [self fb_descendantsMatchingType:XCUIElementTypeCell];
    
  if (cellSnapshots.count == 0) {
      // For the home screen, cells are actually of type XCUIElementTypeIcon
      cellSnapshots = [self fb_descendantsMatchingType:XCUIElementTypeIcon];
  }
   
  if (cellSnapshots.count == 0) {
      // In some cases XCTest will not report Cell Views. In that case grab all descendants and try to figure out scroll directon from them.
      cellSnapshots = self._allDescendants;
  }
  
    return cellSnapshots;
}

- (XCElementSnapshot *)fb_parentCellSnapshot
{
    XCElementSnapshot *targetCellSnapshot = self;
    // XCUIElementTypeIcon is the cell type for homescreen icons
    NSArray<NSNumber *> *acceptableElementTypes = @[
                                                    @(XCUIElementTypeCell),
                                                    @(XCUIElementTypeIcon),
                                                    ];
    if (self.elementType != XCUIElementTypeCell && self.elementType != XCUIElementTypeIcon) {
        targetCellSnapshot = [self fb_parentMatchingOneOfTypes:acceptableElementTypes];
    }
    return targetCellSnapshot;
}

@end

inline static BOOL valuesAreEqual(id value1, id value2)
{
  return value1 == value2 || [value1 isEqual:value2];
}

inline static BOOL isSnapshotTypeAmongstGivenTypes(XCElementSnapshot* snapshot, NSArray<NSNumber *> *types)
{
  for (NSUInteger i = 0; i < types.count; i++) {
   if([@(snapshot.elementType) isEqual: types[i]] || [types[i] isEqual: @(XCUIElementTypeAny)]){
       return YES;
   }
  }
  return NO;
}
