/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCElementSnapshot+FBHitPoint.h"
#import "FBLogger.h"

@implementation XCElementSnapshot (FBHitPoint)

- (CGPoint)fb_hitPoint
{
  @try {
    return [self hitPoint];
  } @catch (NSException *e) {
    [FBLogger logFmt:@"Failed to fetch hit point for %@ - %@", self.debugDescription, e.reason];
    return CGPointMake(-1, -1); // Same what XCTest does
  }
}

@end
