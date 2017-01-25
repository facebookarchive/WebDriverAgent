/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBApplication.h"

#import "FBApplicationProcessProxy.h"
#import "FBRunLoopSpinner.h"
#import "FBMacros.h"
#import "XCAccessibilityElement.h"
#import "XCAXClient_iOS.h"
#import "XCUIApplication.h"
#import "XCUIApplicationImpl.h"
#import "XCUIApplicationProcess.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

@interface FBApplication ()
@property (nonatomic, assign) BOOL fb_isObservingAppImplCurrentProcess;
@end

@implementation FBApplication

+ (instancetype)fb_activeApplication
{
  [[[FBRunLoopSpinner new]
    timeout:5]
   spinUntilTrue:^BOOL{
     return [[XCAXClient_iOS sharedClient] activeApplications].count == 1;
   }];

  XCAccessibilityElement *activeApplicationElement = [[[XCAXClient_iOS sharedClient] activeApplications] firstObject];
  if (!activeApplicationElement) {
    return nil;
  }
  FBApplication *application = [FBApplication appWithPID:activeApplicationElement.processIdentifier];
  NSAssert(nil != application, @"Active application instance is not expected to be equal to nil", nil);
  [application query];
  [application resolve];
  return application;
}

+ (instancetype)appWithPID:(pid_t)processID
{
  if ([NSProcessInfo processInfo].processIdentifier == processID) {
    return nil;
  }
  FBApplication *application = [self fb_registeredApplicationWithProcessID:processID];
  if (application) {
    return application;
  }
  application = [super appWithPID:processID];
  [FBApplication fb_registerApplication:application withProcessID:processID];
  return application;
}

- (void)launch
{
  if (!self.fb_shouldWaitForQuiescence) {
    [self.fb_appImpl addObserver:self forKeyPath:FBStringify(XCUIApplicationImpl, currentProcess) options:(NSKeyValueObservingOptions)(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew) context:nil];
    self.fb_isObservingAppImplCurrentProcess = YES;
  }
  [super launch];
  [FBApplication fb_registerApplication:self withProcessID:self.processID];
}

- (void)terminate
{
  if (self.fb_isObservingAppImplCurrentProcess) {
    [self.fb_appImpl removeObserver:self forKeyPath:FBStringify(XCUIApplicationImpl, currentProcess)];
  }
  [super terminate];
}


#pragma mark - Quiescence

- (void)_waitForQuiescence
{
  if (!self.fb_shouldWaitForQuiescence) {
    return;
  }
  [super _waitForQuiescence];
}

- (XCUIApplicationImpl *)fb_appImpl
{
  if (![self respondsToSelector:@selector(applicationImpl)]) {
    return nil;
  }
  XCUIApplicationImpl *appImpl = [self applicationImpl];
  if (![appImpl respondsToSelector:@selector(currentProcess)]) {
    return nil;
  }
  return appImpl;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
  if (![keyPath isEqualToString:FBStringify(XCUIApplicationImpl, currentProcess)]) {
    return;
  }
  if ([change[NSKeyValueChangeKindKey] unsignedIntegerValue] != NSKeyValueChangeSetting) {
    return;
  }
  XCUIApplicationProcess *applicationProcess = change[NSKeyValueChangeNewKey];
  if (!applicationProcess || ![applicationProcess isMemberOfClass:XCUIApplicationProcess.class]) {
    return;
  }
  [object setValue:[FBApplicationProcessProxy proxyWithApplicationProcess:applicationProcess] forKey:keyPath];
}


#pragma mark - Process registration

static NSMutableDictionary *FBPidToApplicationMapping;

+ (instancetype)fb_registeredApplicationWithProcessID:(pid_t)processID
{
  return FBPidToApplicationMapping[@(processID)];
}

+ (void)fb_registerApplication:(FBApplication *)application withProcessID:(pid_t)processID
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    FBPidToApplicationMapping = [NSMutableDictionary dictionary];
  });
  FBPidToApplicationMapping[@(application.processID)] = application;
}

@end
