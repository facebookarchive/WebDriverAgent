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

NSString *const FBUnknownAttributeException = @"FBUnknownAttributeException";
static NSString *const WD_PREFIX = @"wd";

@implementation FBElementUtils

+ (NSString *)wdAttributeNameForAttributeName:(NSString *)name
{
  NSAssert(name.length > 0, @"Attribute name cannot be empty");
  NSString *resultAttrubuteName = name;
  NSArray *availableProperties = [[FBElementUtils wdProperties] allKeys];
  NSMutableArray *availableGetters = [NSMutableArray new];
  for (id value in [[FBElementUtils wdProperties] allValues]) {
    if ([value isKindOfClass:NSString.class]) {
      [availableGetters addObject:value];
    }
  }
  if (!([availableProperties containsObject:resultAttrubuteName] || [availableGetters containsObject:resultAttrubuteName])) {
    resultAttrubuteName = [NSString stringWithFormat:@"%@%@", WD_PREFIX, [NSString stringWithFormat:@"%@%@", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]]];
  }
  NSString *getterName = [[self.class wdProperties] objectForKey:resultAttrubuteName];
  if ([getterName isKindOfClass:NSString.class]) {
    // Return the corresponding getter name for KVO lookup if exists
    resultAttrubuteName = getterName;
  }
  NSMutableArray *validNames = [NSMutableArray array];
  [validNames addObjectsFromArray:availableProperties];
  [validNames addObjectsFromArray:availableGetters];
  if (![validNames containsObject:resultAttrubuteName]) {
    NSString *description = [NSString stringWithFormat:@"The attribute '%@' is unknown. Valid attribute names are: %@", name, availableProperties];
    @throw [NSException exceptionWithName:FBUnknownAttributeException reason:description userInfo:@{}];
    return nil;
  }
  return resultAttrubuteName;
}

+ (NSSet<NSNumber *> *)uniqueElementTypesWithElements:(NSArray<id<FBElement>> *)elements
{
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [elements enumerateObjectsUsingBlock:^(id<FBElement> element, NSUInteger elementIdx, BOOL *stopElementsEnum) {
    [matchingTypes addObject: @([FBElementTypeTransformer elementTypeWithTypeName:element.wdType])];
  }];
  return matchingTypes.copy;
}

+ (NSDictionary<NSString *, id> *)wdProperties
{
  static NSDictionary *propertiesWithGetters;
  static dispatch_once_t propGettersToken;
  dispatch_once(&propGettersToken, ^{
    NSMutableDictionary *result = [NSMutableDictionary new];
    unsigned int propsCount = 0;
    objc_property_t *properties = protocol_copyPropertyList(objc_getProtocol("FBElement"), &propsCount);
    for (unsigned int i = 0; i < propsCount; ++i) {
      objc_property_t property = properties[i];
      const char *name = property_getName(property);
      NSString *nsName = [NSString stringWithUTF8String:name];
      if (nil == nsName || ![nsName hasPrefix:WD_PREFIX]) {
        continue;
      }
      const char *c_attributes = property_getAttributes(property);
      NSString *attributes = [NSString stringWithUTF8String:c_attributes];
      if (nil == attributes) {
        continue;
      }
      NSArray *splitAttrs = [attributes componentsSeparatedByString:@","];
      // https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
      for(NSString *part in splitAttrs) {
        if ([part hasPrefix:@"G"]) {
          [result setObject:[part substringFromIndex:1] forKey:nsName];
        } else {
          [result setObject:[NSNull null] forKey:nsName];
        }
      }
    }
    free(properties);
    propertiesWithGetters = result.copy;
  });
  return propertiesWithGetters;
}

@end
