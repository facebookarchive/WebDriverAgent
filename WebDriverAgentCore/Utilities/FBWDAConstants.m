/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWDAConstants.h"

#import <UIKit/UIKit.h>

static NSUInteger const DefaultStartingPort = 8100;
static NSUInteger const DefaultPortRange = 100;

@implementation FBWDAConstants

+ (BOOL)isIOS9OrGreater
{
  NSDecimalNumber *versionNumber = [NSDecimalNumber decimalNumberWithString:[UIDevice currentDevice].systemVersion];
  NSComparisonResult comparisonResult = [versionNumber compare:[NSDecimalNumber decimalNumberWithString:@"9.0"]];
  return comparisonResult != NSOrderedAscending;
}

+ (NSRange)bindingPortRange
{
  // Existence of USE_PORT in the environment implies the port range is managed by the launching process.
  if (NSProcessInfo.processInfo.environment[@"USE_PORT"]) {
    return NSMakeRange([NSProcessInfo.processInfo.environment[@"USE_PORT"] integerValue] , 1);
  }

  return NSMakeRange(DefaultStartingPort, DefaultPortRange);
}

+ (BOOL)verboseLoggingEnabled
{
  return [NSProcessInfo.processInfo.environment[@"VERBOSE_LOGGING"] boolValue];
}

@end
