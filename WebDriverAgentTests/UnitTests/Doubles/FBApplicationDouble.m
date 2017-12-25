/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBApplicationDouble.h"

@interface FBApplicationDouble ()
@property (nonatomic, assign, readwrite) BOOL didTerminate;
@end

@implementation FBApplicationDouble

- (instancetype)init
{
  self = [super init];
  if (self) {
    _bundleID = @"some.bundle.identifier";
  }
  return self;
}

- (void)terminate
{
  self.didTerminate = YES;
}

- (NSUInteger)processID
{
  return 0;
}

- (NSString *)bundleID
{
  return @"com.facebook.awesome";
}

- (void)resolve
{

}

- (id)query
{
  return nil;
}

@end
