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
  NSString *propName = [input keyPath];
  NSUInteger dotPos = [propName rangeOfString:@"."].location;
  if (NSNotFound != dotPos) {
    NSString *actualPropName = [propName substringToIndex:dotPos];
    NSString *suffix = [propName substringFromIndex:(dotPos + 1)];
    return [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"%@.%@", [FBElementUtils wdAttributeNameForAttributeName:actualPropName], suffix]];
  }
  return [NSExpression expressionForKeyPath:[FBElementUtils wdAttributeNameForAttributeName:propName]];
}

@end
