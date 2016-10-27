/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "FBElement.h"
#import "FBElementTypeTransformer.h"

NSString *wdAttributeNameForAttributeName(NSString *name)
{
  return [NSString stringWithFormat:@"wd%@", name.capitalizedString];
}

NSSet<NSNumber *> *wdGetUniqueElementsTypes(NSArray<id<FBElement>> *elements)
{
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [elements enumerateObjectsUsingBlock:^(id<FBElement> element, NSUInteger elementIdx, BOOL *stopElementsEnum) {
    [matchingTypes addObject: @([FBElementTypeTransformer elementTypeWithTypeName:element.wdType])];
  }];
  return matchingTypes.copy;
}
