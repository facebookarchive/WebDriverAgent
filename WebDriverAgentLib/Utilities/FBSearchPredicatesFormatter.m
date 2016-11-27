/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSearchPredicatesFormatter.h"
#import "FBElement.h"
#import "FBElementUtils.h"

@implementation NSPredicate (ExtractComparisons)

- (NSPredicate *)predicateByChangingComparisonsWithBlock:(NSPredicate *(^)(NSComparisonPredicate *))block {
  if ([self isKindOfClass: [NSCompoundPredicate class]]) {
    NSCompoundPredicate *compPred = (NSCompoundPredicate *)self;
    NSMutableArray *predicates = [NSMutableArray array];
    for (NSPredicate *predicate in [compPred subpredicates]) {
      NSPredicate *newPredicate = [predicate predicateByChangingComparisonsWithBlock: block];
      if (newPredicate != nil) {
        [predicates addObject: newPredicate];
      }
    }
    return [[NSCompoundPredicate alloc] initWithType: compPred.compoundPredicateType
                                        subpredicates: predicates];
  }
  if ([self isKindOfClass: [NSComparisonPredicate class]]) {
    return block((NSComparisonPredicate *)self);
  }
  return self;
}

@end

NSString *const FBUnknownPredicateKeyException = @"FBUnknownPredicateKeyException";

@implementation FBSearchPredicatesFormatter

+ (NSExpression *)formatExpression:(NSExpression *)input validPropertyNames:(NSArray<NSString *> *)validPropertyNames
{
  if ([input expressionType] != NSKeyPathExpressionType) {
    return input;
  }
  NSString *keyPath = [input keyPath];
  NSString *actualPropName = [FBElementUtils wdAttributeNameForAttributeName:keyPath];
  if ([actualPropName containsString:@"."]) {
    actualPropName = [actualPropName substringToIndex:[actualPropName rangeOfString:@"."].location];
  }
  if (![validPropertyNames containsObject:actualPropName]) {
    NSString *description = [NSString stringWithFormat:@"The key '%@' is unknown in '%@' predicate expression. Valid keys are: %@", actualPropName, input, validPropertyNames];
    @throw [NSException exceptionWithName:FBUnknownPredicateKeyException reason:description userInfo:@{}];
    return nil;
  }
  return [NSExpression expressionForKeyPath:[FBElementUtils wdAttributeNameForAttributeName:keyPath]];
}

+ (NSPredicate *)formatSearchPredicate:(NSPredicate *)input {
  NSArray *validPropertyNames = [FBElementUtils getWDPropertiesNames];
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
