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

static NSUInteger const DefaultStartingPort = 8100;
static NSUInteger const DefaultPortRange = 100;

@implementation FBWDAConstants

+ (BOOL)isIOS9OrGreater
{
  NSDecimalNumber *versionNumber = [NSDecimalNumber decimalNumberWithString:UIATarget.localTarget.systemVersion];
  NSComparisonResult comparisonResult = [versionNumber compare:[NSDecimalNumber decimalNumberWithString:@"9.0"]];
  return comparisonResult != NSOrderedAscending;
}

+ (NSRange)bindingPortRange
{
  // Existence of PORT_OFFSET in the environment implies the port range is managed by the launching process.
  if (NSProcessInfo.processInfo.environment[@"PORT_OFFSET"]) {
    return NSMakeRange(self.startingPort + [NSProcessInfo.processInfo.environment[@"PORT_OFFSET"] integerValue] , 1);
  }

  return NSMakeRange(self.startingPort, DefaultPortRange);
}

+ (BOOL)verboseLoggingEnabled
{
  return [NSProcessInfo.processInfo.environment[@"VERBOSE_LOGGING"] boolValue];
}

#pragma mark Private

+ (NSUInteger)startingPort
{
  NSUInteger port = (NSUInteger) [NSProcessInfo.processInfo.environment[@"STARTING_PORT"] integerValue];
  return port ? port : DefaultStartingPort;
}

@end
