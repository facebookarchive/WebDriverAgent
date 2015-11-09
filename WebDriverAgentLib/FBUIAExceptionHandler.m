/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <RoutingHTTPServer/RouteResponse.h>

#import "FBUIAExceptionHandler.h"

#import "FBAlertViewCommands.h"
#import "FBResponsePayload.h"

extern NSString *kUIAExceptionBadPoint;
extern NSString *kUIAExceptionInvalidElement;

@implementation FBUIAExceptionHandler

- (void)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response
{
  if ([exception.name isEqualToString:FBUAlertObstructingElementException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusUnexpectedAlertPresent, @"Alert is obstructing view");
    [payload dispatchWithResponse:response];
    return;
  }
  if ([[exception name] isEqualToString:kUIAExceptionInvalidElement]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusInvalidElementState, [exception description]);
    [payload dispatchWithResponse:response];
    return;
  }
  if ([[exception name] isEqualToString:kUIAExceptionBadPoint]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, [exception description]);
    [payload dispatchWithResponse:response];
    return;
  }
  id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusStaleElementReference, [exception description]);
  [payload dispatchWithResponse:response];
}

@end

