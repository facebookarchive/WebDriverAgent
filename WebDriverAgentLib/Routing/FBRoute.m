/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRoute.h"
#import "FBRouteRequest-Private.h"

#import <objc/message.h>

#import "FBExceptionHandler.h"
#import "FBResponsePayload.h"
#import "FBSession.h"

@interface FBRoute ()
@property (nonatomic, assign, readwrite) BOOL requiresSession;
@property (nonatomic, copy, readwrite) NSString *verb;
@property (nonatomic, copy, readwrite) NSString *path;

- (void)decorateRequest:(FBRouteRequest *)request;

@end

static NSString *const FBRouteSessionPrefix = @"/session/:sessionID";

@interface FBRoute_TargetAction : FBRoute
@property (nonatomic, strong, readwrite) id target;
@property (nonatomic, assign, readwrite) SEL action;
@end


@implementation FBRoute_TargetAction

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response
{
  [self decorateRequest:request];
  id<FBResponsePayload> (*requestMsgSend)(id, SEL, FBRouteRequest *) = ((id<FBResponsePayload>(*)(id, SEL, FBRouteRequest *))objc_msgSend);
  id<FBResponsePayload> payload = requestMsgSend(self.target, self.action, request);
  [payload dispatchWithResponse:response];
}

@end


@interface FBRoute_Sync : FBRoute
@property (nonatomic, copy, readwrite) FBRouteSyncHandler handler;
@end


@implementation FBRoute_Sync

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response
{
  [self decorateRequest:request];
  id<FBResponsePayload> payload = self.handler(request);
  [payload dispatchWithResponse:response];
}

@end


@implementation FBRoute

+ (instancetype)withVerb:(NSString *)verb path:(NSString *)pathPattern requiresSession:(BOOL)requiresSession
{
  FBRoute *route = [self new];
  route.verb = verb;
  route.path = [FBRoute pathPatternWithSession:pathPattern requiresSession:requiresSession];
  route.requiresSession = requiresSession;
  return route;
}

+ (instancetype)GET:(NSString *)pathPattern
{
  return [self withVerb:@"GET" path:pathPattern requiresSession:YES];
}

+ (instancetype)POST:(NSString *)pathPattern
{
  return [self withVerb:@"POST" path:pathPattern requiresSession:YES];
}

+ (instancetype)PUT:(NSString *)pathPattern
{
  return [self withVerb:@"PUT" path:pathPattern requiresSession:YES];
}

+ (instancetype)DELETE:(NSString *)pathPattern
{
  return [self withVerb:@"DELETE" path:pathPattern requiresSession:YES];
}

+ (NSString *)pathPatternWithSession:(NSString *)pathPattern requiresSession:(BOOL)requiresSession
{
  NSRange range = [pathPattern rangeOfString:FBRouteSessionPrefix];
  if (requiresSession) {
    if (range.location != 0) {
      pathPattern = [FBRouteSessionPrefix stringByAppendingPathComponent:pathPattern];
    }
  } else {
    if (range.location == 0) {
      pathPattern = [pathPattern stringByReplacingCharactersInRange:range withString:@""];
    }
  }
  if (pathPattern.length == 0) {
    pathPattern = @"/";
  }
  return pathPattern;
}

- (instancetype)withoutSession
{
  self.requiresSession = NO;
  return self;
}

- (instancetype)respondWithBlock:(FBRouteSyncHandler)handler
{
  FBRoute_Sync *route = [FBRoute_Sync withVerb:self.verb path:self.path requiresSession:self.requiresSession];
  route.handler = handler;
  return route;
}

- (instancetype)respondWithTarget:(id)target action:(SEL)action
{
  FBRoute_TargetAction *route = [FBRoute_TargetAction withVerb:self.verb path:self.path requiresSession:self.requiresSession];
  route.target = target;
  route.action = action;
  return route;
}

- (void)decorateRequest:(FBRouteRequest *)request
{
  if (!self.requiresSession) {
    return;
  }
  NSString *sessionID = request.parameters[@"sessionID"];
  if (!sessionID) {
    [self raiseNoSessionException];
    return;
  }
  FBSession *session = [FBSession sessionWithIdentifier:sessionID];
  if (!session) {
    [self raiseNoSessionException];
    return;
  }
  request.session = session;
}

- (void)raiseNoSessionException
{
  [[NSException exceptionWithName:FBSessionDoesNotExistException reason:@"Session does not exist" userInfo:nil] raise];
}

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response
{
  [FBResponseWithErrorFormat(@"Unhandled route") dispatchWithResponse:response];
}

@end
