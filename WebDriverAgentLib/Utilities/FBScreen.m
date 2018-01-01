/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreen.h"

@implementation FBScreen

+ (double)scale
{
  id xcScreen = NSClassFromString(@"XCUIScreen");
  if (nil == xcScreen) {
    return [[UIScreen mainScreen] scale];
  }
  id mainScreen = [xcScreen valueForKey:@"mainScreen"];
  return [[mainScreen valueForKey:@"scale"] doubleValue];
}

+ (CGSize)statusBarSizeForApplication:(XCUIApplication *)application
{
  NSArray<XCUIElement *> *statusBars = application.statusBars.allElementsBoundByIndex;
  if (0 == statusBars.count) {
    return CGSizeZero;
  }
  XCUIElement *mainStatusBar = [statusBars objectAtIndex:0];
  if (!mainStatusBar.exists || CGRectIsEmpty(mainStatusBar.frame) || !mainStatusBar.hittable) {
    return CGSizeZero;
  }
  return mainStatusBar.frame.size;
}

@end
