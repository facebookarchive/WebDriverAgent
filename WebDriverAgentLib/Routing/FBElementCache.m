/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCache.h"

#import "FBAlert.h"
#import "XCUIElement.h"
#import "XCUIElement+Utilities.h"


@class UIAElement;

@interface FBElementCache ()
@property (atomic, assign) NSUInteger currentElementIndex;
@property (atomic, strong) NSMutableDictionary *elementCache;
@end

@implementation FBElementCache

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _currentElementIndex = 0;
  _elementCache = [[NSMutableDictionary alloc] init];
  return self;
}

- (NSUInteger)storeElement:(XCUIElement *)element
{
  self.currentElementIndex++;
  self.elementCache[@(self.currentElementIndex)] = element;
  return self.currentElementIndex;
}

- (XCUIElement *)elementForIndex:(NSUInteger)index
{
  XCUIElement *element = self.elementCache[@(index)];
  [element resolve];
  if (element.fb_isObstructedByAlert) {
    [FBAlert throwRequestedItemObstructedByAlertException];
  }
  return element;
}

@end
