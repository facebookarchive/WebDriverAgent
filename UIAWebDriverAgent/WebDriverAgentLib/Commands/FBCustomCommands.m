/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBCustomCommands.h"

#import "FBRouteRequest.h"
#import "FBWDAConstants.h"
#import "UIAApplication.h"
#import "UIATarget.h"

@implementation FBCustomCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return @[
    [[FBRoute POST:@"/homescreen"].withoutSession respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [UIATarget.localTarget deactivateApp];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/deactivateApp"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      id duration = request.arguments[@"duration"];
      @try {
        // TODO(t8051359): This is terrible and we should file a Radar for this.
        if (FBWDAConstants.isIOS9OrGreater) {
          [UIATarget.localTarget lockForDuration:duration];
        } else {
          duration ? [UIATarget.localTarget deactivateAppForDuration:duration] : [UIATarget.localTarget deactivateApp];
        }
      }
      @catch (NSException *exception) {
        if ([exception.reason rangeOfString:@"-lock element not found"].location == NSNotFound) {
          @throw exception;
        }
        if ([UIATarget.localTarget.frontMostApp.name isEqualToString:@"SpringBoard"]) {
          @throw exception;
        }
        // In this case we ignore exception, because it is common false failure that happens since Xcode 7.1
      }
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/timeouts/implicit_wait"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      // This method is intentionally not supported.
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/location"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [[UIATarget localTarget] setLocation:@{ @"latitude": request.arguments[@"latitude"], @"longitude": request.arguments[@"longitude"] }];
      return FBResponseDictionaryWithOK();
    }],
  ];
}

@end
