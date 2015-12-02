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
    [[FBRoute POST:@"/deactivateApp"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      id duration = request.arguments[@"duration"];
      // TODO(t8051359): This is terrible and we should file a Radar for this.
      if (FBWDAConstants.isIOS9OrGreater) {
        [UIATarget.localTarget lockForDuration:duration];
      } else {
        duration ? [UIATarget.localTarget deactivateAppForDuration:duration] : [UIATarget.localTarget deactivateApp];
      }
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/timeouts/implicit_wait"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      // This method is intentionally not supported.
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/location"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [[UIATarget localTarget] setLocation:@{ @"latitude": request.arguments[@"latitude"], @"longitude": request.arguments[@"longitude"] }];
      return FBResponseDictionaryWithOK();
    }],
  ];
}

@end
