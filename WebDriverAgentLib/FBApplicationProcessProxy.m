/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBApplicationProcessProxy.h"

#import "XCUIApplicationProcess.h"

@interface FBApplicationProcessProxy ()
@property (nonatomic, strong) XCUIApplicationProcess *applicationProcess;
@end

@implementation FBApplicationProcessProxy

+ (instancetype)proxyWithApplicationProcess:(XCUIApplicationProcess *)applicationProcess
{
  NSParameterAssert(applicationProcess);
  FBApplicationProcessProxy *proxy = [self.class new];
  proxy.applicationProcess = applicationProcess;
  return proxy;
}

#pragma mark - Override XCUIApplicationProcess methods

- (void)waitForQuiescence
{
  if (!self.shouldWaitForQuiescence) {
    return;
  }
  if ([self.applicationProcess respondsToSelector:@selector(waitForQuiescenceIncludingAnimationsIdle:)]) {
    [self.applicationProcess waitForQuiescenceIncludingAnimationsIdle:YES];
    return;
  }
  [self.applicationProcess waitForQuiescence];
}

- (void)waitForQuiescenceIncludingAnimationsIdle:(BOOL)includeAnimations
{
  if (!self.shouldWaitForQuiescence) {
    return;
  }
  [self.applicationProcess waitForQuiescenceIncludingAnimationsIdle:includeAnimations];
}

#pragma mark - Forward not implemented methods to applicationProcess

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  return self.applicationProcess;
}

#pragma mark - Forward NSKeyValueObserverRegistration methods to applicationProcess

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
  [self.applicationProcess addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context
{
  [self.applicationProcess removeObserver:observer forKeyPath:keyPath context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
  [self.applicationProcess removeObserver:observer forKeyPath:keyPath];
}

@end
