/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXCTestDaemonsProxy.h"
#import "XCTestDriver.h"

#import <objc/runtime.h>


#if !TARGET_OS_TV
#import <WebDriverAgentLib/XCTRunnerDaemonSession.h>
#endif

@implementation FBXCTestDaemonsProxy

+ (id<XCTestManager_ManagerInterface>)testRunnerProxy
{
  static id<XCTestManager_ManagerInterface> proxy = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if ([[XCTestDriver sharedTestDriver] respondsToSelector:@selector(managerProxy)]) {
      proxy = [XCTestDriver sharedTestDriver].managerProxy;
      return;
    }
#if !TARGET_OS_TV
    Class runnerClass = objc_lookUpClass("XCTRunnerDaemonSession");
    proxy = ((XCTRunnerDaemonSession *)[runnerClass sharedSession]).daemonProxy;
#endif
  });
  NSAssert(proxy != NULL, @"Could not determin testRunnerProxy", proxy);
  return proxy;
}

@end
