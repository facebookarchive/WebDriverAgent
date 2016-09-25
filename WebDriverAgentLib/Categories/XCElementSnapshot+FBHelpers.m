/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCElementSnapshot+FBHelpers.h"

#import <KissXML/DDXML.h>

#import "FBFindElementCommands.h"
#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBXPathCreator.h"
#import "XCAXClient_iOS.h"
#import "XCTestDriver.h"
#import "XCTestPrivateSymbols.h"
#import "XCUIElement.h"
#import "XCUIElement+FBWebDriverAttributes.h"

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
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  DDXMLElement *xmlElement = [self XMLElementFromElement:self indexPath:@"top" elementStore:elementStore];
  NSError *error;
  NSArray *xpathNodes = [xmlElement nodesForXPath:xpathQuery error:&error];
  if (![xpathNodes count]) {
    return nil;
  }

  NSMutableArray *matchingSnapshots = [NSMutableArray array];
  for (DDXMLElement *childXMLElement in xpathNodes) {
    XCElementSnapshot *element = [elementStore objectForKey:[[childXMLElement attributeForName:kXMLIndexPathKey] stringValue]];
    if (element) {
      [matchingSnapshots addObject:element];
    }
  }
  return matchingSnapshots;
}

- (DDXMLElement *)XMLElementFromElement:(XCElementSnapshot *)snapshot indexPath:(NSString *)indexPath elementStore:(NSMutableDictionary *)elementStore
{
  DDXMLElement *xmlElement = [[DDXMLElement alloc] initWithName:snapshot.wdType];
  [xmlElement addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:snapshot.wdType]];
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
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"value" stringValue:stringValue]];
  }
  if (snapshot.wdName) {
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"name" stringValue:snapshot.wdName]];
  }
  if (snapshot.wdLabel) {
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"label" stringValue:snapshot.wdLabel]];
  }
  [xmlElement addAttribute:[DDXMLNode attributeWithName:kXMLIndexPathKey stringValue:indexPath]];

  NSArray *children = snapshot.children;
  for (NSUInteger i  = 0; i < [children count]; i++) {
    XCElementSnapshot *childSnapshot = children[i];
    NSString *newIndexPath = [indexPath stringByAppendingFormat:@",%lu", (unsigned long)i];
    elementStore[newIndexPath] = childSnapshot;
    [xmlElement addChild:[self XMLElementFromElement:childSnapshot indexPath:newIndexPath elementStore:elementStore]];
  }
  return xmlElement;
}

- (XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type
{
  NSArray *acceptedParents = @[@(type)];
  return [self fb_parentMatchingOneOfTypes:acceptedParents];
}

- (XCElementSnapshot *)fb_parentMatchingOneOfTypes:(NSArray<NSNumber *> *)types
{
  return [self fb_parentMatchingOneOfTypesWithFilter:types filter:^(XCElementSnapshot *snapshot) {
    return YES;
  }];
}

- (XCElementSnapshot *)fb_parentMatchingOneOfTypesWithFilter:(NSArray<NSNumber *> *)types filter:(BOOL(^)(XCElementSnapshot *snapshot))filter
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
