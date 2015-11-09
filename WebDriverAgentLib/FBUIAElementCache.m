/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBUIAElementCache.h"

#import "FBAlertViewCommands.h"
#import "FBUIAElement.h"

#import "UIAElement.h"

@interface FBUIAElementCache ()

@property (nonatomic, assign, readwrite) NSUInteger incrementingIndex;
@property (nonatomic, strong, readwrite) NSMapTable *axElementsToIds;
@property (nonatomic, strong, readwrite) NSMapTable *idsToElements;

@end

@implementation FBUIAElementCache

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _incrementingIndex = 3;
  _axElementsToIds = [NSMapTable weakToStrongObjectsMapTable];
  _idsToElements = [NSMapTable strongToStrongObjectsMapTable];
  return self;
}

- (NSUInteger)storeElement:(FBUIAElement *)element
{
  @synchronized(self)
  {
    NSNumber *elementNumber = [self.axElementsToIds objectForKey:element.uiaElement.uiaxElement];
    if (elementNumber) {
      return elementNumber.unsignedIntegerValue;
    }

    elementNumber = @(self.incrementingIndex);
    [self.axElementsToIds setObject:elementNumber forKey:element.uiaElement.uiaxElement];
    [self.idsToElements setObject:element forKey:elementNumber];
    self.incrementingIndex++;

    return elementNumber.unsignedIntegerValue;
  }
}

- (FBUIAElement *)elementForIndex:(NSUInteger)index
{
  @synchronized(self)
  {
    FBUIAElement *element = [self.idsToElements objectForKey:@(index)];
    [FBAlertViewCommands ensureElementIsNotObstructedByAlertView:element.uiaElement];
    return element;
  }
}

@end
