/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBOrientationCommands.h"
#import "XCUIDevice+FBRotation.h"
#import "FBRouteRequest.h"
#import "FBMacros.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "XCUIDevice.h"

extern const struct FBWDOrientationValues {
  FBLiteralString portrait;
  FBLiteralString landscapeLeft;
  FBLiteralString landscapeRight;
  FBLiteralString portraitUpsideDown;
} FBWDOrientationValues;

const struct FBWDOrientationValues FBWDOrientationValues = {
  .portrait = @"PORTRAIT",
  .landscapeLeft = @"LANDSCAPE",
  .landscapeRight = @"UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT",
  .portraitUpsideDown = @"UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN",
};

@implementation FBOrientationCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/orientation"] respondWithTarget:self action:@selector(handleGetOrientation:)],
    [[FBRoute POST:@"/orientation"] respondWithTarget:self action:@selector(handleSetOrientation:)],
    [[FBRoute GET:@"/rotation"] respondWithTarget:self action:@selector(handleGetRotation:)],
    [[FBRoute POST:@"/rotation"] respondWithTarget:self action:@selector(handleSetRotation:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetOrientation:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSString *orientation = [self.class interfaceOrientationForApplication:session.activeApplication];
  return FBResponseWithStatus(FBCommandStatusNoError, [[self _wdOrientationsMapping] objectForKey:orientation]);
}

+ (id<FBResponsePayload>)handleSetOrientation:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  if ([self.class setDeviceOrientation:request.arguments[@"orientation"] forApplication:session.activeApplication]) {
    return FBResponseWithOK();
  }
  return FBResponseWithStatus(FBCommandStatusRotationNotAllowed, @"Unable To Rotate Device");
}

+ (id<FBResponsePayload>)handleGetRotation:(FBRouteRequest *)request
{
    XCUIDevice *device = [XCUIDevice sharedDevice];
    UIInterfaceOrientation orientation = request.session.activeApplication.interfaceOrientation;
    return FBResponseWithStatus(FBCommandStatusNoError, device.fb_rotationMapping[@(orientation)]);
}

+ (id<FBResponsePayload>)handleSetRotation:(FBRouteRequest *)request
{
    FBSession *session = request.session;
    if ([self.class setDeviceRotation:request.arguments forApplication:session.activeApplication]) {
        return FBResponseWithOK();
    }
    return FBResponseWithStatus(FBCommandStatusRotationNotAllowed, [NSString stringWithFormat:@"Rotation not supported: %@", request.arguments[@"rotation"]]);
}


#pragma mark - Helpers

+ (NSString *)interfaceOrientationForApplication:(FBApplication *)application
{
  NSNumber *orientation = @(application.interfaceOrientation);
  NSSet *keys = [[self _orientationsMapping] keysOfEntriesPassingTest:^BOOL(id key, NSNumber *obj, BOOL *stop) {
    return [obj isEqualToNumber:orientation];
  }];
  if (keys.count == 0) {
    return @"Unknown orientation";
  }
  return keys.anyObject;
}

+ (BOOL)setDeviceRotation:(NSDictionary *)rotationObj forApplication:(FBApplication *)application
{
  return [[XCUIDevice sharedDevice] fb_setDeviceRotation:rotationObj];
}

+ (BOOL)setDeviceOrientation:(NSString *)orientation forApplication:(FBApplication *)application
{
  NSNumber *orientationValue = [[self _orientationsMapping] objectForKey:[orientation uppercaseString]];
  if (orientationValue == nil) {
    return NO;
  }
  return [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:orientationValue.integerValue];
}

+ (NSDictionary *)_orientationsMapping
{
  static NSDictionary *orientationMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    orientationMap =
    @{
      FBWDOrientationValues.portrait : @(UIDeviceOrientationPortrait),
      FBWDOrientationValues.portraitUpsideDown : @(UIDeviceOrientationPortraitUpsideDown),
      FBWDOrientationValues.landscapeLeft : @(UIDeviceOrientationLandscapeLeft),
      FBWDOrientationValues.landscapeRight : @(UIDeviceOrientationLandscapeRight),
      };
  });
  return orientationMap;
}

/*
 We already have FBWDOrientationValues as orientation descriptions, however the strings are not valid
 WebDriver responses. WebDriver can only receive 'portrait' or 'landscape'. So we can pass the keys
 through this additional filter to ensure we get one of those. It's essentially a mapping from
 FBWDOrientationValues to the valid subset of itself we can return to the client
 */
+ (NSDictionary *)_wdOrientationsMapping
{
  static NSDictionary *orientationMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    orientationMap =
    @{
      FBWDOrientationValues.portrait : FBWDOrientationValues.portrait,
      FBWDOrientationValues.portraitUpsideDown : FBWDOrientationValues.portrait,
      FBWDOrientationValues.landscapeLeft : FBWDOrientationValues.landscapeLeft,
      FBWDOrientationValues.landscapeRight : FBWDOrientationValues.landscapeLeft,
      };
  });
  return orientationMap;
}

@end
