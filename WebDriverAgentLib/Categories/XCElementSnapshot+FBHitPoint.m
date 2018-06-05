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

- (FBElementHitPoint *)fb_hitPoint:(NSError **)error
{
  // Check for Xcode's old hitPoint interface
  if ([self respondsToSelector:@selector(hitPoint)]) {
    @try {
      CGPoint hitPoint = [self hitPoint];
      // Magic Xcode's value that means element is not hittable
      if (CGPointEqualToPoint(hitPoint, CGPointMake(-1, -1))) {
        return nil;
      }
      return [[FBElementHitPoint alloc] initWithCGPoint:hitPoint];
    }
    @catch (NSException *e) {
      [FBLogger logFmt:@"Failed to resolve hit point for %@ - %@", self.debugDescription, e.reason];
      return nil;
    }
  }
  XCUIHitPointResult *result = [self hitPoint:error];
  if (!result) {
    [FBLogger logFmt:@"Failed to resolve hit point for %@ - %@", self.debugDescription, (error ? *error : @"")];
    return nil;
  }
  if (!result.isHittable) {
    return nil;
  }
  return [[FBElementHitPoint alloc] initWithCGPoint:result.hitPoint];
}

- (FBElementHitPoint *)fb_hitPointWithAlternativeOnFailure:(NSError **)error
{
  FBElementHitPoint *hitPoint = [self fb_hitPoint:error];
  if (hitPoint) {
    return hitPoint;
  }
  if (self.suggestedHitpoints.count > 0) {
    return [[FBElementHitPoint alloc] initWithCGPoint:[self.suggestedHitpoints.lastObject CGPointValue]];
  }
  return nil;
}

@end
