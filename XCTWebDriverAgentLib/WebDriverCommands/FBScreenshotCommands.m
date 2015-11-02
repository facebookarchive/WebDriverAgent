/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreenshotCommands.h"



#import "XCAXClient_iOS.h"

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"GET@/session/:sessionID/screenshot" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      id screenshotData = [[XCAXClient_iOS sharedClient] screenshotData];
      
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [screenshotData base64EncodedStringWithOptions:0]));
    },
  };
}

@end
