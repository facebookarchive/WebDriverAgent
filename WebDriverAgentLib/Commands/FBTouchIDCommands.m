/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBTouchIDCommands.h"

#include <notify.h>

#import "FBRouteRequest.h"

@implementation FBTouchIDCommands

+ (NSArray *)routes
{
  return @[
    [[FBRoute POST:@"/simulator/touch_id"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      //Expects argument match=true or match=false (any type whose boolValue evaluates properly)
      BOOL match = [request.arguments[@"match"] boolValue];
      const char *name;
      if (match) {
        name = "com.apple.BiometricKit_Sim.fingerTouch.match";
      } else {
        name = "com.apple.BiometricKit_Sim.fingerTouch.nomatch";
      }
      if (notify_post(name)) {
        return FBResponseDictionaryWithOK();
      } else {
        return FBResponseDictionaryWithStatus(FBCommandStatusUnsupported, nil);
      }
    }]
  ];
}

@end
