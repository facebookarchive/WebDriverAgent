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

@implementation NSExpression (FBFormat)

+ (instancetype)fb_wdExpressionWithExpression:(NSExpression *)input
{
  if ([input expressionType] != NSKeyPathExpressionType) {
    return input;
  }
  NSString *actualPropName = [input keyPath];
  NSString *suffix = nil;
  if ([actualPropName containsString:@"."]) {
    NSUInteger dotPos = [actualPropName rangeOfString:@"."].location;
    actualPropName = [actualPropName substringToIndex:dotPos];
    suffix = [actualPropName substringFromIndex:dotPos];
  }
  if (nil == suffix) {
    return [NSExpression expressionForKeyPath:[FBElementUtils wdAttributeNameForAttributeName:actualPropName]];
  }
  return [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"%@.%@", [FBElementUtils wdAttributeNameForAttributeName:actualPropName], suffix]];
}

@end
