/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXCodeCompatibility.h"

static BOOL FBShouldUseOldElementRootSelector = NO;
static dispatch_once_t onceRootElementToken;
@implementation XCElementSnapshot (FBCompatibility)

- (XCElementSnapshot *)fb_rootElement
{
  dispatch_once(&onceRootElementToken, ^{
    FBShouldUseOldElementRootSelector = [self respondsToSelector:@selector(_rootElement)];
  });
  if (FBShouldUseOldElementRootSelector) {
    return [self _rootElement];
  }
  return [self rootElement];
}

@end


NSString *const FBApplicationMethodNotSupportedException = @"FBApplicationMethodNotSupportedException";

static BOOL FBShouldUseOldAppWithPIDSelector = NO;
static dispatch_once_t onceAppWithPIDToken;
static BOOL FBCanUseActivate = NO;
static dispatch_once_t onceActivate;
static BOOL FBCanUseState = NO;
static dispatch_once_t onceState;
@implementation XCUIApplication (FBCompatibility)

+ (instancetype)fb_applicationWithPID:(pid_t)processID
{
  dispatch_once(&onceAppWithPIDToken, ^{
    FBShouldUseOldAppWithPIDSelector = [XCUIApplication respondsToSelector:@selector(appWithPID:)];
  });
  if (FBShouldUseOldAppWithPIDSelector) {
    return [self appWithPID:processID];
  }
  return [self applicationWithPID:processID];
}

- (void)fb_activate
{
  dispatch_once(&onceActivate, ^{
    FBCanUseActivate = [self respondsToSelector:@selector(activate)];
  });
  if (!FBCanUseActivate) {
    [[NSException exceptionWithName:FBApplicationMethodNotSupportedException reason:@"'activate' method is only supported since iOS 11" userInfo:@{}] raise];
  }
  [self activate];
}

- (NSUInteger)fb_state
{
  SEL stateSelector = NSSelectorFromString(@"state");
  dispatch_once(&onceState, ^{
    FBCanUseState = [self respondsToSelector:stateSelector];
  });
  if (!FBCanUseState) {
    [[NSException exceptionWithName:FBApplicationMethodNotSupportedException reason:@"'state' method is only supported since iOS 11" userInfo:@{}] raise];
  }
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  return [[self performSelector:stateSelector] intValue];
  #pragma clang diagnostic pop
}

@end

