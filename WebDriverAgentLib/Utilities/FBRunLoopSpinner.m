/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRunLoopSpinner.h"

#import <libkern/OSAtomic.h>

static const NSTimeInterval FBWaitInterval = 0.1;

@interface FBRunLoopSpinner ()
@property (nonatomic, copy) NSString *timeoutErrorMessage;
@property (nonatomic, assign) NSTimeInterval timeout;
@end

@implementation FBRunLoopSpinner

+ (void)spinUntilCompletion:(void (^)(void(^completion)()))block
{
  __block volatile uint32_t didFinish = 0;
  block(^{
    OSAtomicOr32Barrier(1, &didFinish);
  });
  while (!didFinish) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBWaitInterval]];
  }
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _timeout = 60;
  }
  return self;
}

- (instancetype)timeoutErrorMessage:(NSString *)timeoutErrorMessage
{
  self.timeoutErrorMessage = timeoutErrorMessage;
  return self;
}

- (instancetype)timeout:(NSTimeInterval)timeout
{
  self.timeout = timeout;
  return self;
}

- (BOOL)spinUntilTrue:(FBRunLoopSpinnerBlock)untilTrue
{
  return [self spinUntilTrue:untilTrue error:nil];
}

- (BOOL)spinUntilTrue:(FBRunLoopSpinnerBlock)untilTrue error:(NSError **)error
{
  NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:self.timeout];
  while (!untilTrue()) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBWaitInterval]];
    if (timeoutDate.timeIntervalSinceNow < 0) {
      NSString *message = (self.timeoutErrorMessage ?: @"FBRunLoopSpinner timeout");
      if (error) {
        *error = [NSError errorWithDomain:@"com.facebook.WebDriverAgent" code:1 userInfo:@{NSLocalizedDescriptionKey : message}];
      }
      return NO;
    }
  }
  return YES;
}

@end
