/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBUnknownCommands.h"

#import "FBRouteRequest.h"

@implementation FBUnknownCommands

#pragma mark - <FBCommandHandler>

+ (BOOL)shouldRegisterAutomatically
{
  return NO;
}

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/*"].withoutSession respond:self.unhandledHandler],
    [[FBRoute POST:@"/*"].withoutSession respond:self.unhandledHandler],
    [[FBRoute PUT:@"/*"].withoutSession respond:self.unhandledHandler],
    [[FBRoute DELETE:@"/*"].withoutSession respond:self.unhandledHandler]
  ];
}

+ (FBRouteSyncHandler)unhandledHandler
{
  return ^ id<FBResponsePayload> (FBRouteRequest *request) {
    return FBResponseDictionaryWithStatus(
      FBCommandStatusUnsupported,
      [NSString stringWithFormat:@"Unhandled endpoint: %@ with parameters %@", request.URL, request.parameters]
    );
  };
}

@end
