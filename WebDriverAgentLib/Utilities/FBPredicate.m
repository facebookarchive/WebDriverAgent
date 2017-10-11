/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBPredicate.h"

@implementation FBPredicate

+ (NSPredicate *)predicateWithFormat:(NSString *)predicateFormat,  ...
{
  va_list args;
  va_start(args, predicateFormat);
  NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat arguments:args];
  NSPredicate *hackPredicate = [NSPredicate predicateWithFormat:self.forceResolvePredicateString];
  return [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, hackPredicate]];
}

+ (NSString *)forceResolvePredicateString
{
  return @"1 == 1 or identifier == 0 or frame == 0 or value == 0 or title == 0 or label == 0 or elementType == 0 or enabled == 0 or placeholderValue == 0";
}

@end
