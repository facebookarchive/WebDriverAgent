/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWebDriverAgent.h"

#import "FBCoreExceptionHandler.h"
#import "FBHTTPOverUSBServer.h"
#import "FBSession-Private.h"
#import "FBWDALogger.h"
#import "FBWebServer.h"
#import "FBXCTExceptionHandler.h"
#import "FBSession.h"

@interface FBWebDriverAgent ()
@property (atomic, strong, readwrite) FBWebServer *routingServer;
@property (atomic, strong, readwrite) FBHTTPOverUSBServer *USBServer;
@end

@implementation FBWebDriverAgent

- (void)start
{
  [FBWDALogger logFmt:@"Built at %s %s", __DATE__, __TIME__];
  self.routingServer = [[FBWebServer alloc] init];
  self.routingServer.exceptionHandlers = @[[FBCoreExceptionHandler new], [FBXCTExceptionHandler new]];
  [self.routingServer startServing];

  self.USBServer = [[FBHTTPOverUSBServer alloc] initWithRoutingServer:self.routingServer.server];
  [self.USBServer startServing];

  [[NSRunLoop mainRunLoop] run];
}

- (void)handleTestFailureWithDescription:(NSString *)failureDescription
{
  FBSession *session = [FBSession activeSession];
  const BOOL isPossibleDeadlock = ([failureDescription rangeOfString:@"Failed to get refreshed snapshot"].location != NSNotFound);
  if (!isPossibleDeadlock) {
    session.didRegisterAXTestFailure = YES;
  }
  else if (session.didRegisterAXTestFailure) {
    [self.routingServer handleAppDeadlockDetection];
  }
}

@end
