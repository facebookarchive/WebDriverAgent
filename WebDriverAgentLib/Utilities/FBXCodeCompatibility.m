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

static BOOL FBShouldUseOldAppWithPIDSelector = NO;
static dispatch_once_t onceAppWithPIDToken;
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

@end

static BOOL FBShouldUseFirstMatchSelector = NO;
static dispatch_once_t onceFirstMatchToken;
@implementation XCUIElementQuery (FBCompatibility)

- (XCUIElement *)fb_firstMatch
{
  SEL firstMatchSelector = NSSelectorFromString(@"firstMatch");
  dispatch_once(&onceFirstMatchToken, ^{
    FBShouldUseFirstMatchSelector = [self respondsToSelector:firstMatchSelector];
  });
  if (FBShouldUseFirstMatchSelector) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    XCUIElement* result = [self performSelector:firstMatchSelector];
    #pragma clang diagnostic pop
    return result.exists ? result : nil;
  }
  if (!self.element.exists) {
    return nil;
  }
  return [self elementBoundByIndex:0];
}

@end

