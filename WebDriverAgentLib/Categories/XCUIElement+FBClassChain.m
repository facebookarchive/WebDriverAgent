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
#import "FBElementUtils.h"
#import "FBMacros.h"
#import "XCElementSnapshot.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

NSString *const FBClassChainQueryParseException = @"FBClassChainQueryParseException";

@implementation XCUIElement (FBClassChain)

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSError *error;
  FBClassChain parsedChain = [FBClassChainQueryParser parseQuery:classChainQuery error:&error];
  if (nil == parsedChain) {
    @throw [NSException exceptionWithName:FBClassChainQueryParseException reason:error.localizedDescription userInfo:error.userInfo];
    return nil;
  }
  NSArray<XCElementSnapshot *> *snapshots = [self.class fb_lookupChain:parsedChain inSnapshot:self.fb_lastSnapshot];
  if (0 == snapshots.count) {
    return @[];
  }
  if (shouldReturnAfterFirstMatch) {
    snapshots = @[[snapshots firstObject]];
  }
  return [self fb_filterDescendantsWithSnapshots:snapshots];
}

+ (NSArray<XCElementSnapshot *> *)fb_matchingChildrenWithSnapshot:(XCElementSnapshot *)root forChainElement:(FBClassChainElement *)chainElement
{
  NSArray *childrenMatches = root.children;
  if (0 == childrenMatches.count) {
    return @[];
  }
  if (XCUIElementTypeAny != chainElement.type) {
    childrenMatches = [childrenMatches filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", FBStringify(XCUIElement, elementType), @(chainElement.type)]];
  }
  if (nil != chainElement.predicate) {
    childrenMatches = [childrenMatches filteredArrayUsingPredicate:(NSPredicate  * _Nonnull)chainElement.predicate];
  }
  NSMutableArray *result = [NSMutableArray array];
  if (0 == chainElement.position) {
    [result addObjectsFromArray:childrenMatches];
  } else if (chainElement.position > 0) {
    if ((NSUInteger)chainElement.position <= childrenMatches.count) {
      [result addObject:[childrenMatches objectAtIndex:chainElement.position - 1]];
    }
  } else {
    if ((NSUInteger)labs(chainElement.position) <= childrenMatches.count) {
      [result addObject:[childrenMatches objectAtIndex:childrenMatches.count + chainElement.position]];
    }
  }
  return result.copy;
}

+ (NSArray<XCElementSnapshot *> *)fb_lookupChain:(FBClassChain)query inSnapshot:(XCElementSnapshot *)root
{
  NSArray *matchingChildren = [self.class fb_matchingChildrenWithSnapshot:root forChainElement:[query firstObject]];
  if (0 == matchingChildren.count) {
    return @[];
  }
  NSMutableArray *result = [NSMutableArray array];
  if (query.count > 1) {
    for (XCElementSnapshot *matchedChild in matchingChildren) {
      [result addObjectsFromArray:[self.class fb_lookupChain:[query subarrayWithRange:NSMakeRange(1, query.count - 1)] inSnapshot:matchedChild]];
    }
  } else {
    [result addObjectsFromArray:matchingChildren];
  }
  return result.copy;
}

@end
