/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBClassChain.h"

#import "FBClassChainQueryParser.h"
#import "FBXCodeCompatibility.h"

NSString *const FBClassChainQueryParseException = @"FBClassChainQueryParseException";

@implementation XCUIElement (FBClassChain)

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSError *error;
  FBClassChain *parsedChain = [FBClassChainQueryParser parseQuery:classChainQuery error:&error];
  if (nil == parsedChain) {
    @throw [NSException exceptionWithName:FBClassChainQueryParseException reason:error.localizedDescription userInfo:error.userInfo];
    return nil;
  }
  NSMutableArray<FBClassChainItem *> *lookupChain = parsedChain.elements.mutableCopy;
  FBClassChainItem *chainItem = lookupChain.firstObject;
  XCUIElement *currentRoot = self;
  XCUIElementQuery *query = [currentRoot fb_queryWithChainItem:chainItem query:nil];
  [lookupChain removeObjectAtIndex:0];
  while (lookupChain.count > 0) {
    BOOL isRootChanged = NO;
    if (chainItem.position < 0 || chainItem.position > 1) {
      // It is necessary to resolve the query if intermediate element index is not zero or one,
      // because predicates don't support search by indexes
      NSArray<XCUIElement *> *currentRootMatch = [self.class fb_matchingElementsWithItem:chainItem query:query shouldReturnAfterFirstMatch:NO];
      if (0 == currentRootMatch.count) {
        return @[];
      }
      currentRoot = currentRootMatch.firstObject;
      isRootChanged = YES;
    }
    chainItem = [lookupChain firstObject];
    query = [currentRoot fb_queryWithChainItem:chainItem query:isRootChanged ? nil : query];
    [lookupChain removeObjectAtIndex:0];
  }
  return [self.class fb_matchingElementsWithItem:chainItem query:query shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
}

- (XCUIElementQuery *)fb_queryWithChainItem:(FBClassChainItem *)item query:(nullable XCUIElementQuery *)query
{
  if (item.isDescendant) {
    if (query) {
      query = [query descendantsMatchingType:item.type];
    } else {
      query = [self descendantsMatchingType:item.type];
    }
  } else {
    if (query) {
      query = [query childrenMatchingType:item.type];
    } else {
      query = [self childrenMatchingType:item.type];
    }
  }
  if (item.predicates) {
    for (FBAbstractPredicateItem *predicate in item.predicates) {
      if ([predicate isKindOfClass:FBSelfPredicateItem.class]) {
        query = [query matchingPredicate:predicate.value];
      } else if ([predicate isKindOfClass:FBDescendantPredicateItem.class]) {
        query = [query containingPredicate:predicate.value];
      }
    }
  }
  return query;
}

+ (NSArray<XCUIElement *> *)fb_matchingElementsWithItem:(FBClassChainItem *)item query:(XCUIElementQuery *)query shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  if (shouldReturnAfterFirstMatch && (item.position == 0 || item.position == 1)) {
    XCUIElement *result = query.fb_firstMatch;
    return result ? @[result] : @[];
  }
  NSArray<XCUIElement *> *allMatches = query.allElementsBoundByAccessibilityElement;
  if (0 == item.position) {
    return allMatches;
  }
  if (item.position > 0 && allMatches.count >= (NSUInteger)ABS(item.position)) {
    return @[[allMatches objectAtIndex:item.position - 1]];
  }
  if (item.position < 0 && allMatches.count >= (NSUInteger)ABS(item.position)) {
    return @[[allMatches objectAtIndex:allMatches.count + item.position]];
  }
  return @[];
}

@end
