/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIDevice+FBRotation.h"

static const NSTimeInterval kFBWebDriverOrientationChangeDelay = 5.0;

@implementation XCUIDevice (FBRotation)

- (BOOL)fb_setDeviceInterfaceOrientation:(UIDeviceOrientation)orientation
{
  FBApplication *application = FBApplication.fb_activeApplication;
  [XCUIDevice sharedDevice].orientation = orientation;
  return [self waitUntilInterfaceIsAtOrientation:orientation application:application];
}

- (BOOL)fb_setDeviceRotation:(NSDictionary *)rotationObj
{
  NSArray<NSNumber *> *keysForRotationObj = [self.fb_rotationMapping allKeysForObject:rotationObj];
  if (keysForRotationObj.count == 0) {
    return NO;
  }
  NSInteger orientation = keysForRotationObj.firstObject.integerValue;
  FBApplication *application = FBApplication.fb_activeApplication;
  [XCUIDevice sharedDevice].orientation = orientation;
  return [self waitUntilInterfaceIsAtOrientation:[XCUIDevice sharedDevice].orientation application:application];
}

- (BOOL)waitUntilInterfaceIsAtOrientation:(NSInteger)orientation application:(FBApplication *)application
{
  NSDate *startDate = [NSDate date];
  while (![@(application.interfaceOrientation) isEqualToNumber:@(orientation)] && (-1 * [startDate timeIntervalSinceNow]) < kFBWebDriverOrientationChangeDelay) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.3, YES);
  }
  return [@(application.interfaceOrientation) isEqualToNumber:@(orientation)];
}

- (NSDictionary *)fb_rotationMapping
{
    static NSDictionary *rotationMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rotationMap =
        @{
          @(UIDeviceOrientationUnknown) : @{@"x" : @(-1), @"y" : @(-1), @"z" : @(-1)},
          @(UIDeviceOrientationPortrait) : @{@"x" : @(0), @"y" : @(0), @"z" : @(0)},
          @(UIDeviceOrientationPortraitUpsideDown) : @{@"x" : @(0), @"y" : @(0), @"z" : @(180)},
          @(UIDeviceOrientationLandscapeLeft) : @{@"x" : @(0), @"y" : @(0), @"z" : @(270)},
          @(UIDeviceOrientationLandscapeRight) : @{@"x" : @(0), @"y" : @(0), @"z" : @(90)},
          @(UIDeviceOrientationFaceUp) : @{@"x" : @(90), @"y" : @(0), @"z" : @(0)},
          @(UIDeviceOrientationFaceDown) : @{@"x" : @(270), @"y" : @(0), @"z" : @(0)},
          };
    });
    return rotationMap;
}

@end
