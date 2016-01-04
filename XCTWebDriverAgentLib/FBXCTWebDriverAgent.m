/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXCTWebDriverAgent.h"

#import "FBCoreExceptionHandler.h"
#import "FBWDALogger.h"
#import "FBWebServer.h"
#import "FBXCTExceptionHandler.h"
#import "FBSession-Private.h"
#import "FBXCTSession.h"

@interface FBXCTWebDriverAgent ()
@property (atomic, strong, readwrite) FBWebServer *server;
@end

@implementation FBXCTWebDriverAgent

- (void)start
{
  [FBWDALogger logFmt:@"Built at %s %s", __DATE__, __TIME__];
  self.server = [[FBWebServer alloc] init];
  self.server.exceptionHandlers = @[[FBCoreExceptionHandler new], [FBXCTExceptionHandler new]];
  [self.server startServing];
  [[NSRunLoop mainRunLoop] run];
}

- (void)handleTestFailureWithDescription:(NSString *)failureDescription
{
  FBXCTSession *session = [FBXCTSession activeSession];
  const BOOL isPossibleDeadlock = ([failureDescription rangeOfString:@"Failed to get refreshed snapshot"].location != NSNotFound);
  if (!isPossibleDeadlock) {
    session.didRegisterAXTestFailure = YES;
  }
  else if (session.didRegisterAXTestFailure) {
    [self.server handleAppDeadlockDetection];
  }
}

@end
