/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBUtilities.h"

#import "FBAlert.h"
#import "FBMathUtils.h"
#import "FBRunLoopSpinner.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@implementation XCUIElement (FBUtilities)

- (BOOL)fb_waitUntilFrameIsStable
{
  __block CGRect frame;
  // Initial wait
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  return
  [[[FBRunLoopSpinner new]
     timeout:10.]
   spinUntilTrue:^BOOL{
     [self resolve];
     const BOOL isSameFrame = FBRectFuzzyEqualToRect(self.wdFrame, frame, FBDefaultFrameFuzzyThreshold);
     frame = self.wdFrame;
     return isSameFrame;
   }];
}

- (BOOL)fb_isObstructedByAlert
{
  return [[FBAlert alertWithApplication:self.application].alertElement fb_obstructsElement:self];
}

- (BOOL)fb_obstructsElement:(XCUIElement *)element
{
  if (!self.exists) {
    return NO;
  }
  [self resolve];
  [element resolve];
  if ([self.lastSnapshot _isAncestorOfElement:element.lastSnapshot]) {
    return NO;
  }
  if ([self.lastSnapshot _matchesElement:element.lastSnapshot]) {
    return NO;
  }
  return YES;
}

- (XCElementSnapshot *)fb_lastSnapshot
{
  if (self.lastSnapshot) {
    return self.lastSnapshot;
  }
  [self resolve];
  return self.lastSnapshot;
}

- (NSDictionary<NSNumber *, NSArray<XCUIElement *> *> *)fb_categorizeDescendants:(NSSet<NSNumber *> *)byTypes
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  [byTypes enumerateObjectsUsingBlock:^(NSNumber *elementTypeAsNumber, BOOL *stopEnum) {
    XCUIElementType elementType = (XCUIElementType)elementTypeAsNumber.unsignedIntegerValue;
    NSArray *descendantsOfType = [[self descendantsMatchingType:elementType] allElementsBoundByIndex];
    result[elementTypeAsNumber] = descendantsOfType;
  }];
  return result.copy;
}

+ (NSArray<XCUIElement *> *)fb_filterElements:(NSDictionary<NSNumber *, NSArray<XCUIElement *> *> *)elementsMap matchingSnapshots:(NSArray<XCElementSnapshot *> *)snapshots useReversedOrder:(BOOL)useReversedOrder
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  NSMutableDictionary<NSNumber *, NSMutableArray<XCUIElement *> *> *mutableElementsMap = [NSMutableDictionary dictionary];
  [elementsMap enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSArray<XCUIElement *> *value, BOOL* stop) {
    [mutableElementsMap setObject:value.mutableCopy forKey:key];
  }];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    NSMutableArray *elements = mutableElementsMap[@(snapshot.elementType)];
    NSEnumerator *elementsEnumerator = [elements objectEnumerator];
    if (useReversedOrder) {
      elementsEnumerator = [elements reverseObjectEnumerator];
    }
    XCUIElement *matchedElement = nil;
    for (XCUIElement *element in elementsEnumerator) {
      if ([element.fb_lastSnapshot _matchesElement:snapshot]) {
        matchedElement = element;
        break;
      }
    }
    if (nil != matchedElement) {
      [matchingElements addObject:matchedElement];
      [elements removeObject:matchedElement];
    }
  }];
  return matchingElements.copy;
}

@end
