/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCTestElementSnapshot.h"

@implementation XCTestElementSnapshot

- (id)wdValue
{
  return @"кирилиця";
}

- (NSString *)wdName
{
  return @"testName";
}

- (NSString *)wdLabel
{
  return @"testLabel";
}

- (NSString *)wdType
{
  return @"XCUIElementTypeOther";
}

- (BOOL)isWDVisible
{
  return YES;
}

- (BOOL)isWDAccessible
{
  return YES;
}

- (BOOL)isWDEnabled
{
  return YES;
}

- (NSArray *)children
{
  return @[];
}

@end
