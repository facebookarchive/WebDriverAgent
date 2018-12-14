/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import "FBApplicationProcessProxy.h"
#import "FBMacros.h"
#import "XCUIApplicationProcess.h"

@interface FBApplicationProcessProxy (NonProxiedMethod)
- (void)objectsMethod;
@end

@implementation FBApplicationProcessProxy (NonProxiedMethod)

- (void)objectsMethod
{
  // intentionally empty
}

@end

@interface FBApplicationProcessProxy (ProxiedMethod)
- (int)proxiedMethod;
@end

@interface XCUIApplicationProcess (TestableMethods)
- (void)objectsMethod;
- (int)proxiedMethod;
@end

@implementation XCUIApplicationProcess (TestableMethods)

- (int)proxiedMethod;
{
  return 1;
}

- (void)objectsMethod
{
  NSString *errorMessage = [NSString stringWithFormat:@"Method %@ must NOT be proxied", NSStringFromSelector(_cmd)];
  NSException * exception = [[NSException alloc] initWithName:@"Test failed" reason:errorMessage userInfo:nil];
  [exception raise];
}

@end

@interface __FBObserver: NSObject
@property (nonatomic, weak) id observedObject;
@property (nonatomic, assign) BOOL observerInvoked;
@end
@implementation __FBObserver
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
  if (object == self.observedObject) {
    self.observerInvoked = YES;
  }
}
@end

@interface FBApplicationProcessProxyTest : XCTestCase
@end

@implementation FBApplicationProcessProxyTest

- (void)testMethodCallIsProxied {
  XCUIApplicationProcess *applicationProcess = [[XCUIApplicationProcess alloc] init];
  FBApplicationProcessProxy *proxy = [FBApplicationProcessProxy proxyWithApplicationProcess:applicationProcess];
  XCTAssertEqual([proxy proxiedMethod], 1);
}

- (void)testMethodCallIsNotProxied {
  XCUIApplicationProcess *applicationProcess = [[XCUIApplicationProcess alloc] init];
  FBApplicationProcessProxy *proxy = [FBApplicationProcessProxy proxyWithApplicationProcess:applicationProcess];
  XCTAssertNoThrow([proxy objectsMethod]);
}

- (void)testProxyIsProxy {
  XCUIApplicationProcess *applicationProcess = [[XCUIApplicationProcess alloc] init];
  FBApplicationProcessProxy *proxy = [FBApplicationProcessProxy proxyWithApplicationProcess:applicationProcess];
  XCTAssertTrue([proxy isProxy]);
}

- (void)testAssertProxyObjectParameter {
  XCUIApplicationProcess *applicationProcess = [[XCUIApplicationProcess alloc] init];
  id proxy = (id)[FBApplicationProcessProxy proxyWithApplicationProcess:applicationProcess];
  XCTAssertThrows([FBApplicationProcessProxy proxyWithApplicationProcess:proxy]);
}

- (void)testObservingProxy {
  XCUIApplicationProcess *applicationProcess = [[XCUIApplicationProcess alloc] init];
  id proxy = (id)[FBApplicationProcessProxy proxyWithApplicationProcess:applicationProcess];
  __FBObserver *observer = [__FBObserver new];
  observer.observedObject = proxy;
  [proxy addObserver:observer forKeyPath:FBStringify(XCUIApplicationProcess, hasCrashReport) options:NSKeyValueObservingOptionNew context:NULL];
  applicationProcess.hasCrashReport = YES;
  [proxy removeObserver:observer forKeyPath:FBStringify(XCUIApplicationProcess, hasCrashReport)];
  XCTAssertTrue(observer.observerInvoked);
}

@end
