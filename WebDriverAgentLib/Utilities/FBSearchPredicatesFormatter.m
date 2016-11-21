/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <objc/runtime.h>

#import "FBSearchPredicatesFormatter.h"
#import "FBElement.h"

@implementation NSPredicate (ExtractComparisons)

- (NSPredicate *)predicateByChangingComparisonsWithBlock:(NSPredicate *(^)(NSComparisonPredicate *))block {
  if ([self isKindOfClass: [NSCompoundPredicate class]]) {
    NSCompoundPredicate *compPred = (NSCompoundPredicate *)self;
    NSMutableArray *predicates = [NSMutableArray array];
    for (NSPredicate *predicate in [compPred subpredicates]) {
      NSPredicate *newPredicate = [predicate predicateByChangingComparisonsWithBlock: block];
      if (newPredicate != nil)
        [predicates addObject: newPredicate];
    }
    return [[NSCompoundPredicate alloc] initWithType: compPred.compoundPredicateType
                                        subpredicates: predicates];
  } if ([self isKindOfClass: [NSComparisonPredicate class]]) {
    return block((NSComparisonPredicate *)self);
  }
  return self;
}

@end

NSString *const wdPrefix = @"wd";
NSString *const FBUnknownPredicateKeyException = @"FBUnknownPredicateKeyException";

@implementation FBSearchPredicatesFormatter

+ (NSArray<NSString *> *)getAllowedPropertyNames {
  NSMutableArray *result = [NSMutableArray array];
  unsigned int propsCount = 0;
  objc_property_t *properties = protocol_copyPropertyList(objc_getProtocol("FBElement"), &propsCount);
  for (unsigned int i = 0; i < propsCount; ++i) {
    objc_property_t property = properties[i];
    const char *name = property_getName(property);
    NSString *nsName = [NSString stringWithUTF8String:name];
    if (nsName) {
      [result addObject:nsName];
    }
  }
  return result.copy;
}

+ (NSString *)shortcutNameToWDPropertyName:(NSString *)originalName {
  NSString *result = originalName.copy;
  if (![result hasPrefix:wdPrefix]) {
    result = [NSString stringWithFormat:@"%@%@%@", wdPrefix, [[result substringToIndex:1] uppercaseString], [result substringFromIndex:1]];
  }
  return result;
}

+ (NSExpression *)formatExpression:(NSExpression *)input validPropertyNames:(NSArray<NSString *> *)validPropertyNames
{
  if ([input expressionType] != NSKeyPathExpressionType) {
    return input;
  }
  NSString *keyPath = [input keyPath];
  NSString *actualPropName = [self.class shortcutNameToWDPropertyName:keyPath];
  if ([actualPropName containsString:@"."]) {
    actualPropName = [actualPropName substringToIndex:[actualPropName rangeOfString:@"."].location];
  }
  if (![validPropertyNames containsObject:actualPropName]) {
    NSString *description = [NSString stringWithFormat:@"The key '%@' is unknown in '%@' predicate expression. Valid keys are: %@", actualPropName, input, validPropertyNames];
    @throw [NSException exceptionWithName:FBUnknownPredicateKeyException reason:description userInfo:@{}];
    return nil;
  }
  return [NSExpression expressionForKeyPath:[self.class shortcutNameToWDPropertyName:keyPath]];
}

+ (NSPredicate *)fb_formatSearchPredicate:(NSPredicate *)input {
  NSMutableArray *validPropertyNames = [NSMutableArray array];
  [validPropertyNames addObjectsFromArray:[FBSearchPredicatesFormatter getAllowedPropertyNames]];
  return [input predicateByChangingComparisonsWithBlock:^NSPredicate *(NSComparisonPredicate *cp) {
    NSExpression *left = [self.class formatExpression:[cp leftExpression] validPropertyNames:validPropertyNames];
    NSExpression *right = [self.class formatExpression:[cp rightExpression] validPropertyNames:validPropertyNames];
    return [NSComparisonPredicate predicateWithLeftExpression: left
                                              rightExpression: right
                                                     modifier: cp.comparisonPredicateModifier
                                                         type: cp.predicateOperatorType
                                                      options: cp.options];
  }];
}

@end
