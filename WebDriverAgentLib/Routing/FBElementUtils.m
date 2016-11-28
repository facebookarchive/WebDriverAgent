/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <objc/runtime.h>

#import "FBElementUtils.h"
#import "FBElementTypeTransformer.h"

static NSString *const WD_PREFIX = @"wd";

@implementation FBElementUtils

+ (NSString *)wdAttributeNameForAttributeName:(NSString *)name
{
  if ([name hasPrefix:WD_PREFIX]) {
    return name;
  }
  return [NSString stringWithFormat:@"%@%@", WD_PREFIX, name.capitalizedString];
}

+ (NSSet<NSNumber *> *)getUniqueElementsTypes:(NSArray<id<FBElement>> *)elements
{
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [elements enumerateObjectsUsingBlock:^(id<FBElement> element, NSUInteger elementIdx, BOOL *stopElementsEnum) {
    [matchingTypes addObject: @([FBElementTypeTransformer elementTypeWithTypeName:element.wdType])];
  }];
  return matchingTypes.copy;
}

+ (NSArray<NSString *> *)getWDPropertiesNames {
  NSMutableArray *result = [NSMutableArray array];
  unsigned int propsCount = 0;
  objc_property_t *properties = protocol_copyPropertyList(objc_getProtocol("FBElement"), &propsCount);
  for (unsigned int i = 0; i < propsCount; ++i) {
    objc_property_t property = properties[i];
    const char *name = property_getName(property);
    NSString *nsName = [NSString stringWithUTF8String:name];
    if (nsName && [nsName hasPrefix:WD_PREFIX]) {
      [result addObject:nsName];
    }
  }
  return result.copy;
}

@end
