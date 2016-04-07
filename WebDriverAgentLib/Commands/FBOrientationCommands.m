/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBOrientationCommands.h"

#import "FBRouteRequest.h"
#import "FBWDAMacros.h"
#import "FBSession.h"
#import "XCUIApplication.h"
#import "XCUIDevice.h"

extern const struct FBWDOrientationValues {
  FBWDALiteralString portrait;
  FBWDALiteralString landscapeLeft;
  FBWDALiteralString landscapeRight;
  FBWDALiteralString portraitUpsideDown;
} FBWDOrientationValues;

const struct FBWDOrientationValues FBWDOrientationValues = {
  .portrait = @"PORTRAIT",
  .landscapeLeft = @"LANDSCAPE",
  .landscapeRight = @"UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT",
  .portraitUpsideDown = @"UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN",
};

const NSTimeInterval kFBWebDriverOrientationChangeDelay = 5.0;

@implementation FBOrientationCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/orientation"] respondWithTarget:self action:@selector(handleGetOrientation:)],
    [[FBRoute POST:@"/orientation"] respondWithTarget:self action:@selector(handleSetOrientation:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetOrientation:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class interfaceOrientationForApplication:session.application]);
}

+ (id<FBResponsePayload>)handleSetOrientation:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  if ([self.class setDeviceOrientation:request.arguments[@"orientation"] forApplication:session.application]) {
    return FBResponseDictionaryWithOK();
  }
  return FBResponseDictionaryWithStatus(FBCommandStatusRotationNotAllowed, @"The orientation specified is not supported by the application");
}


#pragma mark - Helpers

+ (NSString *)interfaceOrientationForApplication:(XCUIApplication *)application
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

+ (BOOL)setDeviceOrientation:(NSString *)orientation forApplication:(XCUIApplication *)application
{
  NSNumber *orientationValue = [[self _orientationsMapping] objectForKey:orientation];
  if (orientationValue == nil) {
    return NO;
  }
  [XCUIDevice sharedDevice].orientation = orientationValue.integerValue;

  // We have a busy loop here while we wait for the orientation to change as we do not have any hooks
  // into the event being handled.
  // If we could just hook into the event handler to know when it has been processed..
  NSDate *startDate = [NSDate date];
  while (![[self interfaceOrientationForApplication:application] isEqualToString:orientation] && (-1 * [startDate timeIntervalSinceNow]) < kFBWebDriverOrientationChangeDelay) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, YES);
  }

  return [[self interfaceOrientationForApplication:application] isEqualToString:orientation];
}

+ (NSDictionary *)_orientationsMapping
{
  static NSDictionary *orientationMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    orientationMap =
    @{
      FBWDOrientationValues.portrait : @1,
      FBWDOrientationValues.portraitUpsideDown : @2,
      FBWDOrientationValues.landscapeLeft : @3,
      FBWDOrientationValues.landscapeRight : @4,
      };
  });
  return orientationMap;
}

@end
