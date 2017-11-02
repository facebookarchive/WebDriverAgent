/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBExceptionHandler.h"

#import <RoutingHTTPServer/RouteResponse.h>

#import "FBAlert.h"
#import "FBResponsePayload.h"
#import "FBSession.h"

NSString *const FBInvalidArgumentException = @"FBInvalidArgumentException";
NSString *const FBSessionDoesNotExistException = @"FBSessionDoesNotExistException";
NSString *const FBApplicationDeadlockDetectedException = @"FBApplicationDeadlockDetectedException";
NSString *const FBElementAttributeUnknownException = @"FBElementAttributeUnknownException";

@implementation FBExceptionHandler

- (BOOL)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response
{
  if ([exception.name isEqualToString:FBApplicationDeadlockDetectedException]) {
    id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusApplicationDeadlockDetected, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }

  if ([exception.name isEqualToString:FBSessionDoesNotExistException]) {
    id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusNoSuchSession, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }

  if ([exception.name isEqualToString:FBInvalidArgumentException]) {
    id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusInvalidArgument, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }

  if ([exception.name isEqualToString:FBElementAttributeUnknownException]) {
    id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusInvalidSelector, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }
  if ([exception.name isEqualToString:FBAlertObstructingElementException]) {
    id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusUnexpectedAlertPresent, @"Alert is obstructing view");
    [payload dispatchWithResponse:response];
    return YES;
  }
  if ([exception.name isEqualToString:FBApplicationCrashedException]) {
    id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusApplicationCrashDetected, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }
  return NO;
}

@end
