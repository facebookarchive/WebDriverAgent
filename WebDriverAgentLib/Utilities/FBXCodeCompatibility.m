/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXCodeCompatibility.h"

#import "XCUIElementQuery.h"

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
  if (!self.fb_isActivateSupported) {
    [[NSException exceptionWithName:FBApplicationMethodNotSupportedException reason:@"'activate' method is not supported by the current iOS SDK" userInfo:@{}] raise];
  }
  [self activate];
}

- (NSUInteger)fb_state
{
  return [[self valueForKey:@"state"] intValue];
}

- (BOOL)fb_isActivateSupported
{
  dispatch_once(&onceActivate, ^{
    FBCanUseActivate = [self respondsToSelector:@selector(activate)];
  });
  return FBCanUseActivate;
}

@end


static BOOL FBShouldUseFirstMatchSelector = NO;
static dispatch_once_t onceFirstMatchToken;
@implementation XCUIElementQuery (FBCompatibility)

- (XCUIElement *)fb_firstMatch
{
  dispatch_once(&onceFirstMatchToken, ^{
    // Unfortunately, firstMatch property does not work properly if
    // the lookup is not executed in application context:
    // https://github.com/appium/appium/issues/10101
    //    FBShouldUseFirstMatchSelector = [self respondsToSelector:@selector(firstMatch)];
    FBShouldUseFirstMatchSelector = NO;
  });
  if (FBShouldUseFirstMatchSelector) {
    XCUIElement* result = self.firstMatch;
    return result.exists ? result : nil;
  }
  if (!self.element.exists) {
    return nil;
  }
  return self.allElementsBoundByAccessibilityElement.firstObject;
}

@end
