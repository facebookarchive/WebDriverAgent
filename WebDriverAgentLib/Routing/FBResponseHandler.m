/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponseHandler.h"

#import "FBAlertViewCommands.h"
#import "FBSessionCommands.h"
#import "FBRequest.h"

extern NSString *kUIAExceptionBadPoint;
extern NSString *kUIAExceptionInvalidElement;

@interface FBResponseHandler_Block : NSObject<FBResponseHandler>

@property (nonatomic, copy, readwrite) FBResponseHandlerBlock block;

@end

@implementation FBResponseHandler_Block

- (id<FBResponse>)handleRequest:(FBRequest *)request
{
  return self.block(request);
}

@end

@interface FBResponseHandler_Chain : NSObject<FBResponseHandler>

@property (nonatomic, copy, readwrite) NSArray *handlers;

@end

@implementation FBResponseHandler_Chain

- (id<FBResponse>)handleRequest:(FBRequest *)request
{
  id<FBResponse> response = nil;
  for (id<FBResponseHandler> handler in self.handlers) {
    response = [handler handleRequest:request];
    if (!response.isSuccessfulStatus) {
      return response;
    }
  }
  return response;
}

@end

@implementation FBResponseHandler

+ (id<FBResponseHandler>)withBlock:(FBResponseHandlerBlock)block
{
  FBResponseHandler_Block *handler = [FBResponseHandler_Block new];
  handler.block = block;
  return handler;
}

+ (id<FBResponseHandler>)sequence:(NSArray *)handlers
{
  NSParameterAssert(handlers.count);
  FBResponseHandler_Chain *handler = [FBResponseHandler_Chain new];
  handler.handlers = handlers;
  return handler;
}

+ (id<FBResponseHandler>)requiringSession:(id<FBResponseHandler>)handler
{
  return [FBResponseHandler sequence:@[
    FBResponseHandler.validateActiveSession,
    handler
  ]];
}

+ (id<FBResponseHandler>)forException:(NSException *)exception
{
  return [self withBlock:^id<FBResponse>(FBRequest *request) {
    if ([exception.name isEqualToString:FBUAlertObstructingElementException]) {
      return [FBResponse withStatus:FBCommandStatusUnexpectedAlertPresent object:@"Alert is obstructing view"];
    }
    if ([[exception name] isEqualToString:kUIAExceptionInvalidElement]) {
      return [FBResponse withStatus:FBCommandStatusInvalidElementState object:[exception description]];
    }
    if ([[exception name] isEqualToString:kUIAExceptionBadPoint]) {
      return [FBResponse withStatus:FBCommandStatusUnhandled object:[exception description]];
    }
    return [FBResponse withStatus:FBCommandStatusStaleElementReference object:[exception description]];
  }];
}

#pragma mark

+ (id<FBResponseHandler>)validateActiveSession
{
  return [FBResponseHandler withBlock:^ id<FBResponse> (FBRequest *request) {
    NSString *sessionID = [request sessionID];
    if (!sessionID) {
      return [FBResponse withStatus:FBCommandStatusNoSuchSession];
    }
    if (!FBSessionCommands.sessionId) {
      return [FBResponse withStatus:FBCommandStatusNoSuchSession];
    }
    if (![sessionID isEqualToString:FBSessionCommands.sessionId]) {
      return [FBResponse withStatus:FBCommandStatusNoSuchSession];
    }
    return [FBResponse okWith:FBSessionCommands.sessionInformation];
  }];
}

@end
