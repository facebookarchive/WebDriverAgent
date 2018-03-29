/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElementDouble.h"

@interface XCUIElementDouble ()
@property (nonatomic, assign, readwrite) BOOL didResolve;
@end

@implementation XCUIElementDouble

- (id)init
{
  self = [super init];
  if (self) {
    self.wdFrame = CGRectMake(0, 0, 0, 0);
    self.wdName = @"testName";
    self.wdLabel = @"testLabel";
    self.wdValue = @"magicValue";
    self.wdVisible = YES;
    self.wdAccessible = YES;
    self.wdEnabled = YES;
    self.children = @[];
    self.wdRect =  @{@"x": @0,
                     @"y": @0,
                     @"width": @0,
                     @"height": @0,
                     };
    self.wdAccessibilityContainer = NO;
    self.elementType = XCUIElementTypeOther;
    self.wdType = @"XCUIElementTypeOther";
    self.wdUID = @"0";
  }
  return self;
}

- (id)fb_valueForWDAttributeName:(NSString *)name
{
  return @"test";
}

- (void)resolve
{
  self.didResolve = YES;
}

- (id)lastSnapshot
{
  return self;
}

@end
