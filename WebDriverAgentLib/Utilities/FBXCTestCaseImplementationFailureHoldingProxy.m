/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXCTestCaseImplementationFailureHoldingProxy.h"

#import <WebDriverAgentLib/_XCTestCaseImplementation.h>

@interface FBXCTestCaseImplementationFailureHoldingProxy ()
@property (nonatomic, strong) _XCTestCaseImplementation *internalImplementation;
@end

@implementation FBXCTestCaseImplementationFailureHoldingProxy

+ (instancetype)proxyWithXCTestCaseImplementation:(_XCTestCaseImplementation *)internalImplementation
{
  FBXCTestCaseImplementationFailureHoldingProxy *proxy = [super alloc];
  proxy.internalImplementation = internalImplementation;
  return proxy;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  return self.internalImplementation;
}

// This will prevent test from quiting on app crash or any other test failure
- (BOOL)shouldHaltWhenReceivesControl
{
  return NO;
}

@end
