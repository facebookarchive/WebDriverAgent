/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIAElement+ChildHelpers.h"

#import "FBWDAMacros.h"

@implementation UIAElement (ChildHelpers)

- (NSArray *)childrenOfClassName:(NSString *)className
{
  FBWDAAssertMainThread();

  [[self class] pushPatience:0];
  NSMutableArray *children = [NSMutableArray array];
  [self _childrenOfClassName:className results:children];
  [[self class] popPatience];

  return children;
}

- (void)_childrenOfClassName:(NSString *)className results:(NSMutableArray *)results
{
  if ([[self className] isEqualToString:className]) {
    [results addObject:self];
  }

  for (UIAElement *childElement in [self elements]) {
    [childElement _childrenOfClassName:className results:results];
  }
}

- (UIAElement *)childOfClassName:(NSString *)className
{
  NSArray *children = [self childrenOfClassName:className];
  return [children count] ? children[0] : nil;
}

@end
