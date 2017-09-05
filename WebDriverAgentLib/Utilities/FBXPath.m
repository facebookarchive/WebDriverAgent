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


@interface ElementAttribute : NSObject

@property (nonatomic, readonly) id<FBElement> element;

+ (nonnull NSString *)name;
- (nullable NSString *)value;

- (instancetype)initWithElement:(id<FBElement>)element;
- (int)recordWithWriter:(xmlTextWriterPtr)writer;

+ (NSArray<Class> *)supportedAttributes;

@end

@interface TypeAttribute : ElementAttribute

@end

@interface ValueAttribute : ElementAttribute

@end

@interface NameAttribute : ElementAttribute

@end

@interface LabelAttribute : ElementAttribute

@end

@interface EnabledAttribute : ElementAttribute

@end

@interface VisibleAttribute : ElementAttribute

@end

@interface DimensionAttribute : ElementAttribute

@end

@interface XAttribute : DimensionAttribute

@end

@interface YAttribute : DimensionAttribute

@end

@interface WidthAttribute : DimensionAttribute

@end

@interface HeigthAttribute : DimensionAttribute

@end

@interface IndexAttribute : ElementAttribute

@property (nonatomic, nonnull, readonly) NSString* indexValue;

- (instancetype)initWithValue:(NSString *)value;

@end


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
  int rc = [FBXPath getSnapshotAsXML:(XCElementSnapshot *)root writer:writer elementStore:nil query:nil];
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
  int rc = [FBXPath getSnapshotAsXML:root writer:writer elementStore:elementStore query:xpathQuery];
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

+ (NSSet<Class> *)elementAttributesWithXPathQuery:(NSString *)query
{
  if ([query rangeOfString:@"@\\*\\b" options:NSRegularExpressionSearch].location != NSNotFound) {
    // read all element attributes if 'star' attribute name pattern is used in xpath query
    return [NSSet setWithArray:ElementAttribute.supportedAttributes];
  }
  NSMutableSet<Class> *result = [NSMutableSet set];
  for (Class attributeCls in ElementAttribute.supportedAttributes) {
    if ([query rangeOfString:[NSString stringWithFormat:@"@%@\\b", [attributeCls name]] options:NSRegularExpressionSearch].location != NSNotFound) {
      [result addObject:attributeCls];
    }
  }
  return result.copy;
}

+ (int)getSnapshotAsXML:(XCElementSnapshot *)root writer:(xmlTextWriterPtr)writer elementStore:(nullable NSMutableDictionary *)elementStore
                  query:(nullable NSString*)query
{
  int rc = xmlTextWriterStartDocument(writer, NULL, _UTF8Encoding, NULL);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartDocument. Error code: %d", rc];
    return rc;
  }
  // Trying to be smart here and only including attributes, that were asked in the query, to the resulting document.
  // This may speed up the lookup significantly in some cases
  rc = [FBXPath generateXMLPresentation:root indexPath:(elementStore != nil ? topNodeIndexPath : nil) elementStore:elementStore includedAttributes:(query == nil ? nil : [self.class elementAttributesWithXPathQuery:query]) writer:writer];
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

+ (int)recordElementAttributes:(xmlTextWriterPtr)writer forElement:(XCElementSnapshot *)element indexPath:(nullable NSString *)indexPath includedAttributes:(nullable NSSet<Class> *)includedAttributes
{
  for (Class attributeCls in ElementAttribute.supportedAttributes) {
    // include all supported attributes by default unless enumerated explicitly
    if (includedAttributes && ![includedAttributes containsObject:attributeCls]) {
      continue;
    }
    int rc = [[[attributeCls alloc] initWithElement:element] recordWithWriter:writer];
    if (rc < 0) {
      return rc;
    }
  }

  if (nil != indexPath) {
    // index path is the special case
    return [[[IndexAttribute alloc] initWithValue:indexPath] recordWithWriter:writer];
  }
  return 0;
}

+ (int)generateXMLPresentation:(XCElementSnapshot *)root indexPath:(nullable NSString *)indexPath elementStore:(nullable NSMutableDictionary *)elementStore includedAttributes:(nullable NSSet<Class> *)includedAttributes writer:(xmlTextWriterPtr)writer
{
  NSAssert((indexPath == nil && elementStore == nil) || (indexPath != nil && elementStore != nil), @"Either both or none of indexPath and elementStore arguments should be equal to nil", nil);

  int rc = xmlTextWriterStartElement(writer, [FBXPath xmlCharPtrForInput:[root.wdType cStringUsingEncoding:NSUTF8StringEncoding]]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterStartElement. Error code: %d", rc];
    return rc;
  }

  rc = [FBXPath recordElementAttributes:writer forElement:root indexPath:indexPath includedAttributes:includedAttributes];
  if (rc < 0) {
    return rc;
  }

  NSArray *children = root.children;
  for (NSUInteger i = 0; i < [children count]; i++) {
    XCElementSnapshot *childSnapshot = children[i];
    NSString *newIndexPath = (indexPath != nil) ? [indexPath stringByAppendingFormat:@",%lu", (unsigned long)i] : nil;
    if (elementStore != nil && newIndexPath != nil) {
      elementStore[newIndexPath] = childSnapshot;
    }
    rc = [self generateXMLPresentation:childSnapshot indexPath:newIndexPath elementStore:elementStore includedAttributes:includedAttributes writer:writer];
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


@implementation ElementAttribute

- (instancetype)initWithElement:(id<FBElement>)element
{
  self = [super init];
  if (self) {
    _element = element;
  }
  return self;
}

+ (NSString *)name
{
  // Override this method in subclasses
  return @"";
}

- (NSString *)value
{
  // Override this method in subclasses
  return nil;
}

- (int)recordWithWriter:(xmlTextWriterPtr)writer
{
  if (nil == self.value) {
    // Skip the attribute if the value equals to nil
    return 0;
  }
  int rc = xmlTextWriterWriteAttribute(writer, [FBXPath safeXmlStringWithString:[self.class name]], [FBXPath safeXmlStringWithString:self.value]);
  if (rc < 0) {
    [FBLogger logFmt:@"Failed to invoke libxml2>xmlTextWriterWriteAttribute(%@='%@'). Error code: %d", [self.class name], self.value, rc];
  }
  return rc;
}

+ (NSArray<Class> *)supportedAttributes
{
  // The list of attributes to be written for each XML node
  // The enumeration order does matter here
  return @[TypeAttribute.class,
           ValueAttribute.class,
           NameAttribute.class,
           LabelAttribute.class,
           EnabledAttribute.class,
           VisibleAttribute.class,
           XAttribute.class,
           YAttribute.class,
           WidthAttribute.class,
           HeigthAttribute.class];
}

@end

@implementation TypeAttribute

+ (NSString *)name
{
  return @"type";
}

- (NSString *)value
{
  return self.element.wdType;
}

@end

@implementation ValueAttribute : ElementAttribute

+ (NSString *)name
{
  return @"value";
}

- (NSString *)value
{
  id idValue = self.element.wdValue;
  if ([idValue isKindOfClass:[NSValue class]]) {
    return [idValue stringValue];
  } else if ([idValue isKindOfClass:[NSString class]]) {
    return idValue;
  }
  return [idValue description];
}

@end

@implementation NameAttribute : ElementAttribute

+ (NSString *)name
{
  return @"name";
}

- (NSString *)value
{
  return self.element.wdName;
}

@end

@implementation LabelAttribute : ElementAttribute

+ (NSString *)name
{
  return @"label";
}

- (NSString *)value
{
  return self.element.wdLabel;
}

@end

@implementation EnabledAttribute : ElementAttribute

+ (NSString *)name
{
  return @"enabled";
}

- (NSString *)value
{
  return self.element.wdEnabled ? @"true" : @"false";
}

@end

@implementation VisibleAttribute : ElementAttribute

+ (NSString *)name
{
  return @"visible";
}

- (NSString *)value
{
  return self.element.wdVisible ? @"true" : @"false";
}

@end

@implementation DimensionAttribute : ElementAttribute

- (NSString *)value
{
  return [NSString stringWithFormat:@"%@", [self.element.wdRect objectForKey:[self.class name]]];
}

@end

@implementation XAttribute : DimensionAttribute

+ (NSString *)name
{
  return @"x";
}

@end

@implementation YAttribute : DimensionAttribute

+ (NSString *)name
{
  return @"y";
}

@end

@implementation WidthAttribute : DimensionAttribute

+ (NSString *)name
{
  return @"width";
}

@end

@implementation HeigthAttribute : DimensionAttribute

+ (NSString *)name
{
  return @"height";
}

@end

@implementation IndexAttribute : ElementAttribute

- (instancetype)initWithValue:(NSString *)value
{
  self = [super initWithElement:nil];
  if (self) {
    _indexValue = value;
  }
  return self;
}

+ (NSString *)name
{
  return kXMLIndexPathKey;
}

- (NSString *)value
{
  return self.indexValue;
}

@end



