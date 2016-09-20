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

#pragma mark - Search by CellByIndex

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXui:(NSString *)locator
{
  NSMutableArray *resultElementList = [NSMutableArray array];
  NSArray *tokens = [locator componentsSeparatedByString:@"|"];
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(getBy.*)\\((.+)\\)" options:NSRegularExpressionCaseInsensitive error:&error];

  __block XCUIElement *currentElement = self;

  [tokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger tokenIdx, BOOL *stopTokenEnum) {

      NSArray *matches = [regex matchesInString:token
                                        options:NSMatchingAnchored
                                          range:NSMakeRange(0, [token length])];
      NSTextCheckingResult *regRes = [matches objectAtIndex:0];
      NSRange funcRange = [regRes rangeAtIndex:1];
      NSRange argRange = [regRes rangeAtIndex:2];
      NSString *func = [token substringWithRange:funcRange];
      NSString *arg = [token substringWithRange:argRange];
      if ([func isEqualToString:@"getById"]) {
        currentElement = [[currentElement fb_descendantsMatchingIdentifier:arg] firstObject];
      } else if ([func isEqualToString:@"getByIndex"]) {
        NSArray *asdf = [arg componentsSeparatedByString:@","];
        NSUInteger type = [[asdf objectAtIndex:0] integerValue];
        NSString *val = [asdf objectAtIndex:1];
        if ([val isEqualToString:@"last"]) {
          currentElement = [[[currentElement descendantsMatchingType:type] allElementsBoundByIndex] lastObject];
        } else {
          NSUInteger indx = [[asdf objectAtIndex:1] integerValue];
          currentElement = [[currentElement descendantsMatchingType:type] elementBoundByIndex:indx];
        }
      } else if ([func isEqualToString:@"getByAttribute"]) {
        NSArray *asdf = [arg componentsSeparatedByString:@","];
        NSString *attrName = [asdf objectAtIndex:0];
        NSString *attrValue = [asdf objectAtIndex:1];
        currentElement = [[currentElement fb_descendantsMatchingProperty:attrName value:attrValue partialSearch:false] firstObject];
      }
  }];
  
  [resultElementList addObject:currentElement];
  return resultElementList.copy;
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
  NSArray *allElements = [[self descendantsMatchingType:XCUIElementTypeAny] allElementsBoundByIndex];
  NSArray *matchingElements = [self filterElements:allElements matchingSnapshots:matchingSnapshots];
  return matchingElements;
}

- (NSArray<XCUIElement *> *)filterElements:(NSArray<XCUIElement *> *)elements matchingSnapshots:(NSArray<XCElementSnapshot *> *)snapshots
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    [elements enumerateObjectsUsingBlock:^(XCUIElement *element, NSUInteger elementIdx, BOOL *stopElementEnum) {
      [element resolve];
      if ([element.lastSnapshot _matchesElement:snapshot]) {
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
