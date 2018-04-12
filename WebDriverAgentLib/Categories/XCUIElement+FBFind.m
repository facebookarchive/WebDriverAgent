/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "XCUIElement+FBFind.h"

#import "FBMacros.h"
#import "FBElementTypeTransformer.h"
#import "FBPredicate.h"
#import "NSPredicate+FBFormat.h"
#import "XCElementSnapshot.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElementQuery.h"
#import "FBElementUtils.h"
#import "FBXCodeCompatibility.h"
#import "FBXPath.h"

@implementation XCUIElement (FBFind)

+ (NSArray<XCUIElement *> *)fb_extractMatchingElementsFromQuery:(XCUIElementQuery *)query shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  if (!shouldReturnAfterFirstMatch) {
    return query.allElementsBoundByAccessibilityElement;
  }
  XCUIElement *matchedElement = query.fb_firstMatch;
  return matchedElement ? @[matchedElement] : @[];
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
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
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

  property = [FBElementUtils wdAttributeNameForAttributeName:property];
  value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
  NSString *operation = partialSearch ?
  [NSString stringWithFormat:@"%@ like '*%@*'", property, value] :
  [NSString stringWithFormat:@"%@ == '%@'", property, value];

  NSPredicate *predicate = [FBPredicate predicateWithFormat:operation];
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = query.allElementsBoundByAccessibilityElement;
  [results addObjectsFromArray:childElements];
}


#pragma mark - Search by Predicate String

- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSPredicate *formattedPredicate = [NSPredicate fb_formatSearchPredicate:predicate];
  NSMutableArray<XCUIElement *> *result = [NSMutableArray array];
  // Include self element into predicate search
  if ([formattedPredicate evaluateWithObject:self.fb_lastSnapshot]) {
    if (shouldReturnAfterFirstMatch) {
      return @[self];
    }
    [result addObject:self];
  }
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:formattedPredicate];
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  return result.copy;
}


#pragma mark - Search by xpath

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  // XPath will try to match elements only class name, so requesting elements by XCUIElementTypeAny will not work. We should use '*' instead.
  xpathQuery = [xpathQuery stringByReplacingOccurrencesOfString:@"XCUIElementTypeAny" withString:@"*"];
  NSArray<XCElementSnapshot *> *matchingSnapshots = [FBXPath matchesWithRootElement:self forQuery:xpathQuery];
  if (0 == [matchingSnapshots count]) {
    return @[];
  }
  if (shouldReturnAfterFirstMatch) {
    XCElementSnapshot *snapshot = matchingSnapshots.firstObject;
    matchingSnapshots = @[snapshot];
  }
  return [self fb_filterDescendantsWithSnapshots:matchingSnapshots];
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
  [result addObjectsFromArray:[self.class fb_extractMatchingElementsFromQuery:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch]];
  return result.copy;
}

@end
