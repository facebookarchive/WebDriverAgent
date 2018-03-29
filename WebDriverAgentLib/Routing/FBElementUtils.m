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
static NSString *const OBJC_PROP_GETTER_PREFIX = @"G";
static NSString *const OBJC_PROP_ATTRIBS_SEPARATOR = @",";

@implementation FBElementUtils

+ (NSString *)wdAttributeNameForAttributeName:(NSString *)name
{
  NSAssert(name.length > 0, @"Attribute name cannot be empty", nil);
  NSDictionary *attributeNamesMapping = [self.class wdAttributeNamesMapping];
  NSString *result = [attributeNamesMapping valueForKey:name];
  if (nil == result) {
    NSString *description = [NSString stringWithFormat:@"The attribute '%@' is unknown. Valid attribute names are: %@", name, [attributeNamesMapping.allKeys sortedArrayUsingSelector:@selector(compare:)]];
    @throw [NSException exceptionWithName:FBUnknownAttributeException reason:description userInfo:@{}];
    return nil;
  }
  return result;
}

+ (NSSet<NSNumber *> *)uniqueElementTypesWithElements:(NSArray<id<FBElement>> *)elements
{
  NSMutableSet *matchingTypes = [NSMutableSet set];
  [elements enumerateObjectsUsingBlock:^(id<FBElement> element, NSUInteger elementIdx, BOOL *stopElementsEnum) {
    [matchingTypes addObject: @([FBElementTypeTransformer elementTypeWithTypeName:element.wdType])];
  }];
  return matchingTypes.copy;
}

+ (NSDictionary<NSString *, NSString *> *)wdAttributeNamesMapping
{
  static NSDictionary *attributeNamesMapping;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableDictionary *wdPropertyGettersMapping = [NSMutableDictionary new];
    unsigned int propsCount = 0;
    Protocol * aProtocol = objc_getProtocol(protocol_getName(@protocol(FBElement)));
    objc_property_t *properties = protocol_copyPropertyList(aProtocol, &propsCount);
    for (unsigned int i = 0; i < propsCount; ++i) {
      objc_property_t property = properties[i];
      const char *name = property_getName(property);
      NSString *nsName = [NSString stringWithUTF8String:name];
      if (nil == nsName || ![nsName hasPrefix:WD_PREFIX]) {
        continue;
      }
      [wdPropertyGettersMapping setObject:[NSNull null] forKey:nsName];
      const char *c_attributes = property_getAttributes(property);
      NSString *attributes = [NSString stringWithUTF8String:c_attributes];
      if (nil == attributes) {
        continue;
      }
      // https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
      NSArray *splitAttrs = [attributes componentsSeparatedByString:OBJC_PROP_ATTRIBS_SEPARATOR];
      for (NSString *part in splitAttrs) {
        if ([part hasPrefix:OBJC_PROP_GETTER_PREFIX]) {
          [wdPropertyGettersMapping setObject:[part substringFromIndex:1] forKey:nsName];
          break;
        }
      }
    }
    free(properties);

    NSMutableDictionary *resultCache = [NSMutableDictionary new];
    for (NSString *propName in wdPropertyGettersMapping) {
      if ([[wdPropertyGettersMapping valueForKey:propName] isKindOfClass:NSNull.class]) {
        // no getter
        [resultCache setValue:propName forKey:propName];
      } else {
        // has getter method
        [resultCache setValue:[wdPropertyGettersMapping objectForKey:propName] forKey:propName];
      }
      NSString *aliasName;
      if (propName.length <= WD_PREFIX.length + 1) {
        aliasName = [NSString stringWithFormat:@"%@",
                        [propName substringWithRange:NSMakeRange(WD_PREFIX.length, 1)].lowercaseString];
      } else {
        NSString *propNameWithoutPrefix = [propName substringFromIndex:WD_PREFIX.length];
        NSString *firstPropNameCharacter = [propNameWithoutPrefix substringWithRange:NSMakeRange(0, 1)];
        if (![propNameWithoutPrefix isEqualToString:[propNameWithoutPrefix uppercaseString]]) {
          // Lowercase the first character for the alias if the property name is not an uppercase abbreviation
          firstPropNameCharacter = firstPropNameCharacter.lowercaseString;
        }
        aliasName = [NSString stringWithFormat:@"%@%@", firstPropNameCharacter, [propNameWithoutPrefix substringFromIndex:1]];
      }
      if ([[wdPropertyGettersMapping valueForKey:propName] isKindOfClass:NSNull.class]) {
        // no getter
        [resultCache setValue:propName forKey:aliasName];
      } else {
        // has getter method
        [resultCache setValue:[wdPropertyGettersMapping objectForKey:propName] forKey:aliasName];
      }
    }
    attributeNamesMapping = resultCache.copy;
  });
  return attributeNamesMapping.copy;
}

static BOOL FBShouldUsePayloadForUIDExtraction = YES;
static dispatch_once_t oncePayloadToken;
+ (NSString *)uidWithAccessibilityElement:(XCAccessibilityElement *)element
{
  dispatch_once(&oncePayloadToken, ^{
    FBShouldUsePayloadForUIDExtraction = [element respondsToSelector:@selector(payload)];
  });
  unsigned long long elementId;
  if (FBShouldUsePayloadForUIDExtraction) {
    elementId = [[element.payload objectForKey:@"uid.elementID"] longLongValue];
  } else {
    elementId = [[element valueForKey:@"_elementID"] longLongValue];
  }
  int processId = element.processIdentifier;
  uint8_t b[16] = {0};
  memcpy(b, &elementId, sizeof(long long));
  memcpy(b + sizeof(long long), &processId, sizeof(int));
  NSUUID *uuidValue = [[NSUUID alloc] initWithUUIDBytes:b];
  return uuidValue.UUIDString;
}

@end
