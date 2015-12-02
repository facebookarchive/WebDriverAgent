/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBUIAWebDriverAgent.h"

#import "FBAutomationTargetDelegate.h"
#import "FBCoreExceptionHandler.h"
#import "FBUIAElementCache.h"
#import "FBUIAExceptionHandler.h"
#import "FBWDALogger.h"
#import "FBWebServer.h"
#import "UIAApplication.h"
#import "UIATarget.h"

@interface FBUIAWebDriverAgent ()
@property (atomic, strong, readwrite) id<UIATargetDelegate> automationDelegate;
@property (atomic, strong, readwrite) FBWebServer *server;
@end


@implementation FBUIAWebDriverAgent

+ (instancetype)sharedAgent
{
  static id agent;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    agent = [self.class new];
  });
  return agent;
}

- (void)start
{
  [FBWDALogger logFmt:@"Built at %s %s", __DATE__, __TIME__];
  self.automationDelegate = [[FBAutomationTargetDelegate alloc] init];
  [[UIATarget localTarget] setDelegate:self.automationDelegate];
  self.server = [[FBWebServer alloc] init];
  self.server.exceptionHandlers = @[[FBCoreExceptionHandler new], [FBUIAExceptionHandler new]];
  [self.server startServing];
  [[NSRunLoop mainRunLoop] run];
}

@end
