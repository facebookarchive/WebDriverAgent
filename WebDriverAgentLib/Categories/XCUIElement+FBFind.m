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

+ (NSArray<XCUIElement *> *)lookupDescendants:(XCUIElementQuery *)query shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  if (shouldReturnAfterFirstMatch) {
    XCUIElement *match = [query elementBoundByIndex:0];
    if (match && [match exists]) {
      return @[match];
    }
    return @[];
  }
  return [query allElementsBoundByIndex];
}


#pragma mark - Search by ClassName

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassName:(NSString *)className shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType type = [FBElementTypeTransformer elementTypeWithTypeName:className];
  if (self.elementType == type || type == XCUIElementTypeAny) {
    [result addObject:self];
    if (shouldReturnAfterFirstMatch) {
      return result.copy;
    }
  }
  XCUIElementQuery *query = [self descendantsMatchingType:type];
  [result addObjectsFromArray:[self.class lookupDescendants:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
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

- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  return [self.class lookupDescendants:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
}


#pragma mark - Search by xpath

- (NSArray<XCElementSnapshot *> *)getMatchedSnapshotsByXPathQuery:(NSString *)xpathQuery
{
  // XPath will try to match elements only class name, so requesting elements by XCUIElementTypeAny will not work. We should use '*' instead.
  xpathQuery = [xpathQuery stringByReplacingOccurrencesOfString:@"XCUIElementTypeAny" withString:@"*"];
  return [self.lastSnapshot fb_descendantsMatchingXPathQuery:xpathQuery];
}

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSArray *matchingSnapshots = [self getMatchedSnapshotsByXPathQuery:xpathQuery];
  if (0 == [matchingSnapshots count]) {
    return @[];
  }
  if (shouldReturnAfterFirstMatch) {
    matchingSnapshots = @[[matchingSnapshots firstObject]];
  }
  // Prefiltering elements speeds up search by XPath a lot, because [element resolve] is the most expensive operation here
  NSSet *byTypes = wdGetUniqueElementsTypes(matchingSnapshots);
  NSDictionary *categorizedDescendants = [self categorizeDescendants:byTypes];
  NSArray *matchingElements = [XCUIElement filterElements:categorizedDescendants matchingSnapshots:matchingSnapshots useReversedOrder:[xpathQuery containsString:@"last()"]];
  return matchingElements;
}

+ (NSArray<XCUIElement *> *)filterElements:(NSDictionary<NSNumber *, NSArray<XCUIElement *> *> *)elementsMap matchingSnapshots:(NSArray<XCElementSnapshot *> *)snapshots useReversedOrder:(BOOL)useReversedOrder
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    NSArray *elements = elementsMap[@(snapshot.elementType)];
    NSEnumerator *elementsEnumerator = [elements objectEnumerator];
    if (useReversedOrder) {
      elementsEnumerator = [elements reverseObjectEnumerator];
    }
    for (XCUIElement *element in elementsEnumerator) {
      if ([element.fb_lastSnapshot _matchesElement:snapshot]) {
        [matchingElements addObject:element];
        break;
      }
    };
  }];
  return matchingElements.copy;
}


#pragma mark - Search by Accessibility Id

- (NSArray<XCUIElement *> *)fb_descendantsMatchingIdentifier:(NSString *)accessibilityId shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSMutableArray *result = [NSMutableArray array];
  if (self.identifier == accessibilityId) {
    [result addObject:self];
    if (shouldReturnAfterFirstMatch) {
      return result.copy;
    }
  }
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:accessibilityId];
  [result addObjectsFromArray:[self.class lookupDescendants:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  return result.copy;
}

@end
