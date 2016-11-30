/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSExpression+FBFormat.h"
#import "FBElementUtils.h"

static NSString *const FBUnknownPredicateKeyException = @"FBUnknownPredicateKeyException";

@implementation NSExpression (FBFormat)

+ (instancetype)fb_wdExpressionWithExpression:(NSExpression *)input
{
  if ([input expressionType] != NSKeyPathExpressionType) {
    return input;
  }
  NSString *keyPath = [input keyPath];
  NSString *actualPropName = [FBElementUtils wdAttributeNameForAttributeName:keyPath];
  if ([actualPropName containsString:@"."]) {
    actualPropName = [actualPropName substringToIndex:[actualPropName rangeOfString:@"."].location];
  }
  NSArray *validPropertiesNames = [self.class cachedWDPropertyNames];
  if (![validPropertiesNames containsObject:actualPropName]) {
    NSString *description = [NSString stringWithFormat:@"The key '%@' is unknown in '%@' predicate expression. Valid keys are: %@", actualPropName, input, validPropertiesNames];
    @throw [NSException exceptionWithName:FBUnknownPredicateKeyException reason:description userInfo:@{}];
    return nil;
  }
  return [NSExpression expressionForKeyPath:[FBElementUtils wdAttributeNameForAttributeName:keyPath]];
}

+ (NSArray<NSString *> *)cachedWDPropertyNames
{
  static NSArray<NSString *> *cachedWDPropertyNames;
  static dispatch_once_t token;
  dispatch_once(&token, ^{
    cachedWDPropertyNames = [FBElementUtils wdPropertyNames];
  });
  return cachedWDPropertyNames;
}

@end
