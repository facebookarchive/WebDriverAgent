/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWDAConstants.h"

#import "UIATarget.h"

@implementation FBWDAConstants

+ (BOOL)isIOS9OrGreater
{
  NSDecimalNumber *versionNumber = [NSDecimalNumber decimalNumberWithString:UIATarget.localTarget.systemVersion];
  NSComparisonResult comparisonResult = [versionNumber compare:[NSDecimalNumber decimalNumberWithString:@"9.0"]];
  return comparisonResult != NSOrderedAscending;
}

@end
