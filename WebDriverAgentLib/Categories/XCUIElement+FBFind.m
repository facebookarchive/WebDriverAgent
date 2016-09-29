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

- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate {
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
  if (nil == matchingSnapshots) {
    return @[];
  }
  // Prefiltering elements speeds up search by XPath a lot, because [element resolve] is the most expensive operation here
  NSArray *allElementsByType = [self filterPotentialMatchesByType:matchingSnapshots];
  NSArray *matchingElements = [self filterElements:allElementsByType matchingSnapshots:matchingSnapshots];
  return matchingElements;
}

- (NSArray<XCUIElement *> *)filterPotentialMatchesByType:(NSArray<XCElementSnapshot *> *)snapshots {
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    [matchingTypes addObject:@(snapshot.elementType)];
  }];
  NSMutableArray *result = [NSMutableArray array];
  [matchingTypes enumerateObjectsUsingBlock:^(NSNumber *elementTypeAsNumber, BOOL *stopEnum) {
    XCUIElementType elementType = (XCUIElementType)elementTypeAsNumber.unsignedIntegerValue;
    NSArray *descendantsOfType = [[self descendantsMatchingType:elementType] allElementsBoundByIndex];
    if (XCUIElementTypeAny == elementType) {
      // No need to continue filtering - all descendants should be in the resulting list
      [result removeAllObjects];
      *stopEnum=YES;
    }
    [result addObjectsFromArray:descendantsOfType];
  }];
  return result.copy;
}

- (NSArray<XCUIElement *> *)filterElements:(NSArray<XCUIElement *> *)elements matchingSnapshots:(NSArray<XCElementSnapshot *> *)snapshots
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  [elements enumerateObjectsUsingBlock:^(XCUIElement *element, NSUInteger elementIdx, BOOL *stopElementEnum) {
    [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
      id lastSnapshot = [element lastSnapshot];
      if (nil == lastSnapshot) {
        [element resolve];
        lastSnapshot = [element lastSnapshot];
      }
      if ([lastSnapshot _matchesElement:snapshot]) {
        [matchingElements addObject:element];
        *stopSnapshotEnum = YES;
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
