/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBCoreExceptionHandler.h"

#import <RoutingHTTPServer/RouteResponse.h>

#import "FBResponsePayload.h"

NSString *const FBSessionDoesNotExistException = @"FBSessionDoesNotExistException";
NSString *const FBApplicationDeadlockDetectedException = @"FBApplicationDeadlockDetectedException";
NSString *const FBElementAttributeUnknownException = @"FBElementAttributeUnknownException";

@implementation FBCoreExceptionHandler

- (BOOL)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response
{
  if ([exception.name isEqualToString:FBApplicationDeadlockDetectedException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusApplicationDeadlockDetected, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }

  if ([exception.name isEqualToString:FBSessionDoesNotExistException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusNoSuchSession, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }

  if ([exception.name isEqualToString:FBElementAttributeUnknownException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusInvalidSelector, [exception description]);
    [payload dispatchWithResponse:response];
    return YES;
  }
  return NO;
}

@end
