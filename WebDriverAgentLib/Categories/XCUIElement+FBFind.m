/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "XCUIElement+FBFind.h"

#import "FBElementTypeTransformer.h"
#import "XCElementSnapshot.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@implementation XCUIElement (FBFind)


#pragma mark - Search by ClassName

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassName:(NSString *)className
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType type = [FBElementTypeTransformer elementTypeWithTypeName:className];
  if (self.elementType == type || type == XCUIElementTypeAny) {
    [result addObject:self];
  }
  [result addObjectsFromArray:[[self descendantsMatchingType:type] allElementsBoundByIndex]];
  return result.copy;
}


#pragma mark - Search by property value

- (NSArray<XCUIElement *> *)fb_descendantsMatchingProperty:(NSString *)property value:(NSString *)value partialSearch:(BOOL)partialSearch
{
  NSMutableArray *elements = [NSMutableArray array];
  [self descendantsWithProperty:property value:value partial:partialSearch results:elements];
  return elements;
}

- (void)descendantsWithProperty:(NSString *)property value:(NSString *)value partial:(BOOL)partialSearch results:(NSMutableArray<XCUIElement *> *)results
{
  if (partialSearch) {
    NSString *text = [self fb_valueForWDAttributeName:property];
    BOOL isString = [text isKindOfClass:[NSString class]];
    if (isString && [text rangeOfString:value].location != NSNotFound) {
      [results addObject:self];
    }
  } else {
    if ([[self fb_valueForWDAttributeName:property] isEqual:value]) {
      [results addObject:self];
    }
  }

  property = wdAttributeNameForAttributeName(property);
  value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
  NSString *operation = partialSearch ?
  [NSString stringWithFormat:@"%@ like '*%@*'", property, value] :
  [NSString stringWithFormat:@"%@ == '%@'", property, value];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:operation];
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = [query allElementsBoundByIndex];
  [results addObjectsFromArray:childElements];
}


#pragma mark - Search by Predicate String

- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate
{
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = [query allElementsBoundByIndex];
  return childElements;
}


#pragma mark - Search by xpath

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery
{
  // XPath will try to match elements only class name, so requesting elements by XCUIElementTypeAny will not work. We should use '*' instead.
  xpathQuery = [xpathQuery stringByReplacingOccurrencesOfString:@"XCUIElementTypeAny" withString:@"*"];
  NSArray *matchingSnapshots = [self.lastSnapshot fb_descendantsMatchingXPathQuery:xpathQuery];
  if (0 == [matchingSnapshots count]) {
    return @[];
  }
  // Prefiltering elements speeds up search by XPath a lot, because [element resolve] is the most expensive operation here
  NSSet *matchedTypes = [XCUIElement getSnapshotsTypes:matchingSnapshots];
  NSDictionary *elementsByType = [self splitElementsByType:matchingSnapshots byTypes:matchedTypes];
  NSArray *matchingElements = [self filterElements:elementsByType matchingSnapshots:matchingSnapshots];
  return matchingElements;
}

+(NSSet *)getSnapshotsTypes:(NSArray<XCElementSnapshot *> *)matchingSnapshots
{
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [matchingSnapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    [matchingTypes addObject:@(snapshot.elementType)];
  }];
  return matchingTypes;
}

- (NSDictionary<NSNumber *, NSArray<XCUIElement *> *> *)splitElementsByType:(NSArray<XCElementSnapshot *> *)snapshots byTypes:(NSSet *)types
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  [types enumerateObjectsUsingBlock:^(NSNumber *elementTypeAsNumber, BOOL *stopEnum) {
    XCUIElementType elementType = (XCUIElementType)elementTypeAsNumber.unsignedIntegerValue;
    NSArray *descendantsOfType = [[self descendantsMatchingType:elementType] allElementsBoundByIndex];
    result[elementTypeAsNumber] = descendantsOfType;
  }];
  return result.copy;
}

- (NSArray<XCUIElement *> *)filterElements:(NSDictionary<NSNumber *, NSArray<XCUIElement *> *> *)elementsMap matchingSnapshots:(NSArray<XCElementSnapshot *> *)snapshots
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    NSArray *elements = elementsMap[@(snapshot.elementType)];
    [elements enumerateObjectsUsingBlock:^(XCUIElement *element, NSUInteger elementIdx, BOOL *stopElementEnum) {
      if ([[element fb_lastSnapshot] _matchesElement:snapshot]) {
        [matchingElements addObject:element];
        *stopElementEnum = YES;
      }
    }];
  }];
  return matchingElements.copy;
}


#pragma mark - Search by Accessibility Id

- (NSArray<XCUIElement *> *)fb_descendantsMatchingIdentifier:(NSString *)accessibilityId
{
  NSMutableArray *result = [NSMutableArray array];
  if (self.identifier == accessibilityId) {
    [result addObject:self];
  }
  NSArray *children = [[[self descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:accessibilityId] allElementsBoundByIndex];
  [result addObjectsFromArray: children];
  return result.copy;
}

@end
