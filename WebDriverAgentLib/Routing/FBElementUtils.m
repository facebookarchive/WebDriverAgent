/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementUtils.h"
#import "FBElementTypeTransformer.h"

@implementation FBElementUtils

+ (NSString *)fb_attributeNameForAttributeName:(NSString *)name
{
  return [NSString stringWithFormat:@"wd%@", name.capitalizedString];
}

+ (NSSet<NSNumber *> *)fb_getUniqueElementsTypes:(NSArray<id<FBElement>> *)elements
{
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [elements enumerateObjectsUsingBlock:^(id<FBElement> element, NSUInteger elementIdx, BOOL *stopElementsEnum) {
    [matchingTypes addObject: @([FBElementTypeTransformer elementTypeWithTypeName:element.wdType])];
  }];
  return matchingTypes.copy;
}

@end
