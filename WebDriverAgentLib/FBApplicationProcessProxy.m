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

@interface __FBObserverProxy : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, weak) NSProxy *targetedProxy;

@end

@implementation __FBObserverProxy

+ (instancetype)observerProxy:(NSObject *)observer targetedProxy:(NSProxy *)targetedProxy keyPath:(NSString *)keyPath
{
  NSParameterAssert(observer);
  NSParameterAssert(targetedProxy);
  __FBObserverProxy *proxy = [__FBObserverProxy new];
  proxy.observer = observer;
  proxy.targetedProxy = targetedProxy;
  proxy.keyPath = keyPath;
  return proxy;
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
  [self.observer observeValueForKeyPath:keyPath ofObject:self.targetedProxy change:change context:context];
}

@end

@interface FBApplicationProcessProxy ()
@property (nonatomic, strong) XCUIApplicationProcess *applicationProcess;
@property (nonatomic, strong) NSMutableArray *observerProxies;
@end

@implementation FBApplicationProcessProxy

+ (instancetype)proxyWithApplicationProcess:(XCUIApplicationProcess *)applicationProcess
{
  NSParameterAssert(applicationProcess);
  NSParameterAssert([[applicationProcess class] isEqual:XCUIApplicationProcess.class]);
  FBApplicationProcessProxy *proxy = [[self.class alloc] init];
  proxy.applicationProcess = applicationProcess;
  proxy.observerProxies = [NSMutableArray array];
  return proxy;
}

- (instancetype)init {
  return self;
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

- (void)forwardInvocation:(NSInvocation *)invocation
{
  [invocation invokeWithTarget:self.applicationProcess];
}

- (nullable NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
  return [self.applicationProcess methodSignatureForSelector:sel];
}


#pragma mark - NSKeyValueObserving

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
  __FBObserverProxy *observerProxy = [__FBObserverProxy observerProxy:observer targetedProxy:self keyPath:keyPath];
  [self.observerProxies addObject:observerProxy];
  [self.applicationProcess addObserver:observerProxy forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
  [self removeObserver:observer forKeyPath:keyPath context:NULL];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context
{
  __FBObserverProxy *observerProxy = [self findObserverProxyForObserver:observer forKeyPath:keyPath];
  NSAssert(observerProxy != nil, @"Inconsistency removing observer for %@ (%@) on FBApplicationProcessProxy. Failed to map observer to it's proxy. ", observer, keyPath);
  [self.observerProxies removeObject:observerProxy];
  [self.applicationProcess removeObserver:observerProxy forKeyPath:keyPath context:context];
}

- (__FBObserverProxy *)findObserverProxyForObserver:(NSObject *)targetObserver forKeyPath:(NSString *)keyPath
{
  __block __FBObserverProxy *observerProxy = nil;
  [self.observerProxies enumerateObjectsUsingBlock:^(__FBObserverProxy *obj, NSUInteger _, BOOL *stop) {
    if (obj.observer == targetObserver && [obj.keyPath isEqualToString:keyPath]) {
      observerProxy = obj;
      *stop = YES;
    }
  }];
  return observerProxy;
}

@end
