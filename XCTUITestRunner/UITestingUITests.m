/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <XCTWebDriverAgentLib/_XCTestCaseImplementation.h>
#import <XCTWebDriverAgentLib/FBCoreExceptionHandler.h>
#import <XCTWebDriverAgentLib/FBWDALogger.h>
#import <XCTWebDriverAgentLib/FBXCTWebDriverAgent.h>
#import <XCTWebDriverAgentLib/XCTestCase.h>

#import "FBDebugLogDelegateDecorator.h"

@interface FBXCTestCaseImplementationFailureHoldingProxy : NSProxy
@property (nonatomic, strong) _XCTestCaseImplementation *internalImplementation;

+ (instancetype)proxyWithXCTestCaseImplementation:(_XCTestCaseImplementation *)internalImplementation;

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

// This will prevert test from quiting on app crash or any other test failure
- (BOOL)shouldHaltWhenReceivesControl
{
  return NO;
}

@end


@interface UITestingUITests : XCTestCase
@property (nonatomic, strong) FBXCTWebDriverAgent *agent;
@end

@implementation UITestingUITests

+ (void)setUp
{
  [FBDebugLogDelegateDecorator decorateXCTestLogger];
  [super setUp];
}

- (void)setUp
{
  [super setUp];
  self.continueAfterFailure = YES;
  self.agent = [FBXCTWebDriverAgent new];
}

- (void)testRunner
{
  self.internalImplementation = (_XCTestCaseImplementation *)[FBXCTestCaseImplementationFailureHoldingProxy proxyWithXCTestCaseImplementation:self.internalImplementation];
  [self.agent start];
}

- (void)_enqueueFailureWithDescription:(NSString *)description inFile:(NSString *)filePath atLine:(NSUInteger)lineNumber expected:(BOOL)expected
{
  [FBWDALogger logFmt:@"Enqueue Failure: %@ %@ %lu %d", description, filePath, (unsigned long)lineNumber, expected];
  [self.agent handleTestFailureWithDescription:description];
}

@end
