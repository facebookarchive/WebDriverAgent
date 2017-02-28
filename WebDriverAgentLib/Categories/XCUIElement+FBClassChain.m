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

NSString *const FBClassChainQueryParseException = @"FBClassChainQueryParseException";

@implementation XCUIElement (FBClassChain)

- (NSArray <XCUIElement *> *)fb_matchingElementsWithSnapshots:(NSArray<XCElementSnapshot *> *)snapshots usingChain:(FBClassChain)chain
{
  XCUIElementQuery *elementsQuery = [self childrenMatchingType:[chain firstObject].type];
  for (NSUInteger level = 1; level < chain.count; ++level) {
    elementsQuery = [elementsQuery childrenMatchingType:[chain objectAtIndex:level].type];
  }
  NSMutableArray *candidateElements = [NSMutableArray arrayWithArray:elementsQuery.allElementsBoundByIndex];
  if ([chain lastObject].position < 0 && candidateElements.count > 1) {
    // reverse candidates list if the expected element position is negative
    // to speed up the lookup
    candidateElements = [[candidateElements reverseObjectEnumerator] allObjects].mutableCopy;
  }
  NSMutableArray *result = [NSMutableArray array];
  NSMutableArray *unmatchedSnapshots = snapshots.mutableCopy;
  NSUInteger candidateElementIdx = 0;
  while (candidateElementIdx < candidateElements.count) {
    XCUIElement *candidateElement = [candidateElements objectAtIndex:candidateElementIdx];
    NSUInteger snapshotIdx = 0;
    BOOL isMatchFound = NO;
    while (snapshotIdx < unmatchedSnapshots.count) {
      if ([candidateElement.fb_lastSnapshot _matchesElement:[unmatchedSnapshots objectAtIndex:snapshotIdx]]) {
        [result addObject:candidateElement];
        [unmatchedSnapshots removeObjectAtIndex:snapshotIdx];
        isMatchFound = YES;
        break;
      }
      ++snapshotIdx;
    }
    if (0 == unmatchedSnapshots.count) {
      break;
    }
    if (isMatchFound) {
      [candidateElements removeObjectAtIndex:candidateElementIdx];
    } else {
      ++candidateElementIdx;
    }
  }
  return result.copy;
}

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSError *error;
  FBClassChain parsedChain = [FBClassChainQueryParser parseQuery:classChainQuery error:&error];
  if (nil == parsedChain) {
    @throw [NSException exceptionWithName:FBClassChainQueryParseException reason:error.localizedDescription userInfo:error.userInfo];
    return nil;
  }
  NSMutableArray *unmatchedSnapshots = [self.class fb_lookupChain:parsedChain inSnapshot:self.fb_lastSnapshot].mutableCopy;
  if (0 == unmatchedSnapshots.count) {
    return @[];
  }
  if (shouldReturnAfterFirstMatch) {
    [unmatchedSnapshots removeObjectsInRange:NSMakeRange(1, unmatchedSnapshots.count - 1)];
  }
  return [self fb_matchingElementsWithSnapshots:unmatchedSnapshots usingChain:parsedChain];
}

+ (NSArray<XCElementSnapshot *> *)fb_matchingChildrenWithSnapshot:(XCElementSnapshot *)root forChainElement:(FBClassChainElement *)chainElement
{
  NSArray *childrenMatchingByType = root.children;
  if (0 == childrenMatchingByType.count) {
    return @[];
  }
  if (XCUIElementTypeAny != chainElement.type) {
    childrenMatchingByType = [childrenMatchingByType filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", FBStringify(XCUIElement, elementType), @(chainElement.type)]];
  }
  NSMutableArray *result = [NSMutableArray array];
  if (0 == chainElement.position) {
    [result addObjectsFromArray:childrenMatchingByType];
  } else if (chainElement.position > 0) {
    if ((NSUInteger)chainElement.position <= childrenMatchingByType.count) {
      [result addObject:[childrenMatchingByType objectAtIndex:chainElement.position - 1]];
    }
  } else {
    if ((NSUInteger)labs(chainElement.position) <= childrenMatchingByType.count) {
      [result addObject:[childrenMatchingByType objectAtIndex:childrenMatchingByType.count + chainElement.position]];
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
