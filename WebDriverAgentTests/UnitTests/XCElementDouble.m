/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCElementDouble.h"

@interface XCElementDouble ()
@property (nonatomic, copy, readwrite) NSString *wdName;
@property (nonatomic, copy, readwrite) NSString *wdLabel;
@property (nonatomic, copy, readwrite) NSString *wdType;
@property (nonatomic, strong, nullable, readwrite) id wdValue;
@property (nonatomic, readwrite, getter = isWDEnabled) BOOL wdEnabled;
@property (nonatomic, readwrite, getter = isWDVisible) BOOL wdVisible;
@property (nonatomic, readwrite, getter = isWDAccessible) BOOL wdAccessible;
@property (nonatomic, copy, readwrite) NSArray *children;
@end

@implementation XCElementDouble
- (BOOL)isWDAccessibilityContainer
{
  return NO;
}

- (CGRect)wdFrame
{
  return CGRectMake(0, 0, 0, 0);
}

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return @"test";
}

- (NSDictionary *)wdRect
{
  return
  @{
    @"x": @(0),
    @"y": @(0),
    @"width": @(0),
    @"height": @(0),
    };
}

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
