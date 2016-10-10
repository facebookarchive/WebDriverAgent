/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIDevice+FBHealthCheck.h"

#import "XCUIDevice+FBRotation.h"
#import "XCUIApplication+FBHelpers.h"

@implementation XCUIDevice (FBHealthCheck)

- (BOOL)fb_healthCheckWithApplication:(nullable XCUIApplication *)application
{
  if (![self fb_elementQueryCheckWithApplication:application]) {
    return NO;
  }
  if (![self fb_deviceInteractionCheck]) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_elementQueryCheckWithApplication:(nullable XCUIApplication *)application
{
  if (!application) {
    return NO;
  }
  if (!application.label) {
    return NO;
  }
  if ([application descendantsMatchingType:XCUIElementTypeAny].count == 0 ) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_deviceInteractionCheck
{
  [self pressButton:XCUIDeviceButtonHome];
  return YES;
}

@end
