/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBUnknownCommands.h"

#import "FBRequest.h"
#import "UIATarget.h"

@implementation FBUnknownCommands

#pragma mark - <FBCommandHandler>

+ (BOOL)shouldRegisterAutomatically
{
  return NO;
}

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/*"].sessionNotRequired respond:self.unhandledHandler],
    [[FBRoute POST:@"/*"].sessionNotRequired respond:self.unhandledHandler],
    [[FBRoute PUT:@"/*"].sessionNotRequired respond:self.unhandledHandler],
    [[FBRoute DELETE:@"/*"].sessionNotRequired respond:self.unhandledHandler]
  ];
}

+ (FBResponseHandlerBlock)unhandledHandler
{
  return ^ id<FBResponse> (FBRequest *request) {
    return [FBResponse
      withStatus:FBCommandStatusUnsupported
      object:[NSString stringWithFormat:@"Unhandled endpoint: %@ with parameters %@", request.URL, request.parameters]
    ];
  };
}

@end
