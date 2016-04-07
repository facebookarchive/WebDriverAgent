/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXCTExceptionHandler.h"

#import <RoutingHTTPServer/RouteResponse.h>

#import "FBAlertViewCommands.h"
#import "FBResponsePayload.h"
#import "FBSession.h"

@implementation FBXCTExceptionHandler

- (BOOL)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response
{
  if ([exception.name isEqualToString:FBUAlertObstructingElementException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusUnexpectedAlertPresent, @"Alert is obstructing view");
    [payload dispatchWithResponse:response];
    return YES;
  }
  if ([exception.name isEqualToString:FBApplicationCrashedException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusStaleElementReference, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }
  return NO;
}

@end
