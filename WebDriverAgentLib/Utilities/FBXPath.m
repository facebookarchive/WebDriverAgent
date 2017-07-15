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


@interface FBXmlAttributeRecord : NSObject

@property(nonatomic, readonly, nonnull) NSString *name;
@property(nonatomic, readonly, nullable) NSString *value;

- (instancetype)initWithName:(NSString *)name value:(nullable NSString *)value;

@end

@implementation FBXmlAttributeRecord

- (instancetype)initWithName:(NSString *)name value:(nullable NSString *)value
{
  self = [super init];
  if (self) {
    _name = name;
    _value = value;
  }
  return self;
}

@end


const static char *_UTF8Encoding = "UTF-8";
static NSString *const kXMLUIDAttribute = @"uid";
static NSString *const kXMLTypeAttribute = @"type";
static NSString *const kXMLNameAttribute = @"name";
static NSString *const kXMLValueAttribute = @"value";
static NSString *const kXMLLabelAttribute = @"label";
static NSString *const kXMLEnabledAttribute = @"enabled";
static NSString *const kXMLVisibleAttribute = @"visible";
static NSString *const kXMLRectXAttribute = @"x";
static NSString *const kXMLRectYAttribute = @"y";
static NSString *const kXMLRectWidthAttribute = @"width";
static NSString *const kXMLRectHeightAttribute = @"height";

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
  int rc = [self.class xmlRepresentationWithElement:root writer:writer elementStore:nil xpathQuery:nil];
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
  int rc = [self.class xmlRepresentationWithElement:root writer:writer elementStore:elementStore xpathQuery:xpathQuery];
  if (rc < 0) {
    xmlFreeTextWriter(writer);
    xmlFreeDoc(doc);
    [FBXPath throwException:XCElementSnapshotXPathQueryEvaluationException forQuery:xpathQuery];
    return nil;
  }

  xmlXPathObjectPtr queryResult = [FBXPath evaluateXPathWithQuery:xpathQuery document:doc];
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
    xmlChar *attrValue = xmlGetProp(currentNode, [self.class safeXmlStringWithString:kXMLUIDAttribute]);
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

+ (void)buildElementsTreeWithFlatElements:(NSArray<XCUIElement *> *)flatElements attributesMapping:(NSDictionary<NSString *, NSArray<FBXmlAttributeRecord *> *> *)attributesMapping elementsTree:(NSDictionary<NSString *, NSArray<XCUIElement *> *> *)elementsTree xpathQuery:(nullable NSString *)xpathQuery
{
  for (XCUIElement *node in flatElements) {
    NSString *nodeUID = [NSString stringWithFormat:@"%@", @(node.wdUID)];
    NSArray<FBXmlAttributeRecord *> *elementAttributes;
    if (xpathQuery) {
      elementAttributes = [self.class elementAttributesWithElement:node applyFilter:[self.class attributeNamesWithXPathQuery:xpathQuery] uid:nodeUID];
    } else {
      elementAttributes = [self.class elementAttributesWithElement:node applyFilter:nil uid:nodeUID];
    }
    [attributesMapping setValue:elementAttributes forKey:nodeUID];
    XCElementSnapshot *nodeSnapshot = node.fb_lastSnapshot;
    if (nil == nodeSnapshot.parent) {
      continue;
    }
    NSString *parentUID = [NSString stringWithFormat:@"%@", @(nodeSnapshot.parent.wdUID)];
    if ([elementsTree objectForKey:parentUID]) {
      NSMutableArray<XCUIElement *> *group = [elementsTree objectForKey:parentUID].mutableCopy;
      [group addObject:node];
      [elementsTree setValue:group forKey:parentUID];
    } else {
      NSMutableArray<XCUIElement *> *group = [NSMutableArray array];
      [group addObject:node];
      [elementsTree setValue:group.copy forKey:parentUID];
    }
  }
}

+ (NSSet<NSString *> *)attributeNamesWithXPathQuery:(NSString *)xpathQuery
{
  NSMutableSet<NSString *> *result = [NSMutableSet set];
  // element type and uid are always included
  [result addObject:kXMLTypeAttribute];
  [result addObject:kXMLUIDAttribute];
  for (NSString *attributeName in @[kXMLNameAttribute,
                                    kXMLValueAttribute,
                                    kXMLLabelAttribute,
                                    kXMLVisibleAttribute,
                                    kXMLEnabledAttribute,
                                    kXMLVisibleAttribute,
                                    kXMLRectXAttribute,
                                    kXMLRectYAttribute,
                                    kXMLRectWidthAttribute,
                                    kXMLRectHeightAttribute]) {
    if ([xpathQuery rangeOfString:[NSString stringWithFormat:@"@%@\\b", attributeName] options:NSRegularExpressionSearch].location != NSNotFound) {
      [result addObject:attributeName];
    }
  }
  return result.copy;
}

+ (int)xmlRepresentationWithElement:(id<FBElement>)root writer:(xmlTextWriterPtr)writer elementStore:(nullable NSDictionary<NSString *, id<FBElement>> *)elementStore xpathQuery:(nullable NSString *)xpathQuery
{
  int rc = xmlTextWriterStartDocument(writer, NULL, _UTF8Encoding, NULL);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartDocument. Error code: %d", rc];
    return rc;
  }
  NSString *rootUID = [NSString stringWithFormat:@"%@", @(root.wdUID)];
  if ([root respondsToSelector:@selector(children)]) {
    rc = [self.class recursiveXMLRepresentationWithSnapshot:(XCElementSnapshot *)root elementStore:elementStore writer:writer];
  } else {
    NSArray<XCUIElement *> *flatElements = [(XCUIElement *)root descendantsMatchingType:XCUIElementTypeAny].allElementsBoundByIndex;
    NSMutableDictionary<NSString *, NSArray<XCUIElement *> *> *elementsTree = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSArray<FBXmlAttributeRecord *> *> *attributesMapping = [NSMutableDictionary dictionary];
    [self.class buildElementsTreeWithFlatElements:flatElements attributesMapping:attributesMapping elementsTree:elementsTree xpathQuery:xpathQuery];
    NSSet<NSString *> *attributeNames = nil;
    if (xpathQuery) {
      // Speed up xpath lookup by excluding unnecessary attributes from the tree
      attributeNames = [self.class attributeNamesWithXPathQuery:xpathQuery];
    }
    [attributesMapping setValue:[self.class elementAttributesWithElement:root applyFilter:attributeNames uid:rootUID] forKey:rootUID];
    rc = [self.class recursiveXMLRepresentationWithElementUID:rootUID elementsTree:elementsTree.copy elementStore:elementStore attributesMapping:attributesMapping.copy writer:writer];
  }
  if (rc < 0) {
    [FBLogger log:@"Failed to generate XML presentation of a screen element"];
    return rc;
  }
  if (elementStore) {
    // The current node should be in the store as well
    [elementStore setValue:root forKey:rootUID];
  }
  rc = xmlTextWriterEndDocument(writer);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterEndDocument. Error code: %d", rc];
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

+ (xmlXPathObjectPtr)evaluateXPathWithQuery:(NSString *)xpathQuery document:(xmlDocPtr)doc
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

+ (int)recordElementWithAttributes:(NSArray<FBXmlAttributeRecord *> *)attributes includeIndex:(BOOL)includeIndex writer:(xmlTextWriterPtr)writer
{
  for (FBXmlAttributeRecord *record in attributes) {
    if (nil == record.value || (!includeIndex && [record.name isEqualToString:kXMLUIDAttribute])) {
      continue;
    }
    int rc = xmlTextWriterWriteAttribute(writer, [self.class safeXmlStringWithString:record.name], [self.class safeXmlStringWithString:record.value]);
    if (rc < 0) {
      [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(%@='%@'). Error code: %d", record.name, record.value, rc];
      return rc;
    }
  }
  return 0;
}

+ (NSArray<FBXmlAttributeRecord *> *)elementAttributesWithElement:(id<FBElement>)element applyFilter:(nullable NSSet<NSString *> *)namesFilter uid:(NSString *)uid
{
  // Each invokation of XCUIElement property causes an extra call to the UI structure and thus is expensive
  // So we are trying to cache the actual values where possible
  NSMutableArray<FBXmlAttributeRecord *> *result = [NSMutableArray array];
  if (!namesFilter || [namesFilter containsObject:kXMLTypeAttribute]) {
    [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLTypeAttribute value:element.wdType]];
  }
  if (!namesFilter || [namesFilter containsObject:kXMLValueAttribute]) {
    NSString *value = element.wdValue;
    if (value) {
      [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLValueAttribute value:value]];
    }
  }
  if (!namesFilter || [namesFilter containsObject:kXMLNameAttribute]) {
    NSString *name = element.wdName;
    if (name) {
      [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLNameAttribute value:name]];
    }
  }
  if (!namesFilter || [namesFilter containsObject:kXMLLabelAttribute]) {
    NSString *label = element.wdLabel;
    if (label) {
      [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLLabelAttribute value:label]];
    }
  }
  if (!namesFilter || [namesFilter containsObject:kXMLEnabledAttribute]) {
    [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLEnabledAttribute value:element.wdEnabled ? @"true" : @"false"]];
  }
  if (!namesFilter || [namesFilter containsObject:kXMLVisibleAttribute]) {
    [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLVisibleAttribute value:element.wdVisible ? @"true" : @"false"]];
  }
  NSDictionary *rect = nil;
  for (NSString *attrName in @[kXMLRectXAttribute,
                               kXMLRectYAttribute,
                               kXMLRectWidthAttribute,
                               kXMLRectHeightAttribute]) {
    if (!namesFilter || [namesFilter containsObject:attrName]) {
      if (!rect) {
        rect = element.wdRect;
      }
      [result addObject:[[FBXmlAttributeRecord alloc] initWithName:attrName value:[rect[attrName] stringValue]]];
    }
  }
  if (!namesFilter || [namesFilter containsObject:kXMLUIDAttribute]) {
    [result addObject:[[FBXmlAttributeRecord alloc] initWithName:kXMLUIDAttribute value:uid]];
  }
  return result.copy;
}

+ (nullable NSString *)attributeValueWithName:(NSString *)name attributes:(NSArray<FBXmlAttributeRecord *> *)attributes
{
  for (FBXmlAttributeRecord *attribute in attributes) {
    if ([attribute.name isEqualToString:name]) {
      return attribute.value;
    }
  }
  return nil;
}

+ (int)recursiveXMLRepresentationWithSnapshot:(XCElementSnapshot *)root elementStore:(nullable NSDictionary<NSString *, id<FBElement>> *)elementStore writer:(xmlTextWriterPtr)writer
{
  int rc = xmlTextWriterStartElement(writer, [FBXPath xmlCharPtrForInput:[root.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement. Error code: %d", rc];
    return rc;
  }
  
  NSArray<FBXmlAttributeRecord *> *attributes = [self.class elementAttributesWithElement:root applyFilter:nil uid:[NSString stringWithFormat:@"%@", @(root.wdUID)]];
  rc = [self.class recordElementWithAttributes:attributes includeIndex:elementStore != nil writer:writer];
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

+ (int)recursiveXMLRepresentationWithElementUID:(NSString *)rootUID elementsTree:(NSDictionary<NSString *, NSArray<XCUIElement *> *> *)elementsTree elementStore:(nullable NSDictionary<NSString *, id<FBElement>> *)elementStore attributesMapping:(NSDictionary<NSString *, NSArray<FBXmlAttributeRecord *> *> *)attributesMapping writer:(xmlTextWriterPtr)writer
{
  NSArray<FBXmlAttributeRecord *> *rootAttributes = [attributesMapping objectForKey:rootUID];
  if (nil == rootAttributes) {
    [FBLogger logFmt:@"Cannot extract attributes list for the element with UID %@", rootUID];
    return -1;
  }
  int rc = xmlTextWriterStartElement(writer, [self.class safeXmlStringWithString:[self.class attributeValueWithName:kXMLTypeAttribute attributes:rootAttributes]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement. Error code: %d", rc];
    return rc;
  }
  
  rc = [self.class recordElementWithAttributes:rootAttributes includeIndex:elementStore != nil writer:writer];
  if (rc < 0) {
    return rc;
  }
  
  NSArray<XCUIElement *> *children = [elementsTree objectForKey:rootUID];
  if (children) {
    for (XCUIElement *child in children) {
      NSString *childUID = [NSString stringWithFormat:@"%@", @(child.wdUID)];
      if (elementStore) {
        [elementStore setValue:child forKey:childUID];
      }
      rc = [self recursiveXMLRepresentationWithElementUID:childUID elementsTree:elementsTree elementStore:elementStore attributesMapping:attributesMapping writer:writer];
      if (rc < 0) {
        return rc;
      }
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
