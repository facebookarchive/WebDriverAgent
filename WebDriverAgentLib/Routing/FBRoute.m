/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRoute.h"

#import "FBResponsePayload.h"

@interface FBRoute ()

@property (nonatomic, copy, readwrite) NSString *verb;
@property (nonatomic, copy, readwrite) NSString *path;

@end

@interface FBRoute_Sync : FBRoute

@property (nonatomic, copy, readwrite) FBRouteSyncHandler handler;

@end

@implementation FBRoute_Sync

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response
{
  id<FBResponsePayload> payload = self.handler(request);
  [payload dispatchWithResponse:response];
}

@end

@interface FBRoute_Async : FBRoute

@property (nonatomic, copy, readwrite) FBRouteAsyncHandler handler;

@end

@implementation FBRoute_Async

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response
{
  self.handler(request, ^(id<FBResponsePayload> payload){
    [payload dispatchWithResponse:response];
  });
}

@end

@implementation FBRoute

+ (instancetype)withVerb:(NSString *)verb path:(NSString *)pathPattern
{
  FBRoute *route = [self new];
  route.verb = verb;
  route.path = pathPattern;
  return route;
}

+ (instancetype)GET:(NSString *)pathPattern
{
  return [self withVerb:@"GET" path:pathPattern];
}

+ (instancetype)POST:(NSString *)pathPattern
{
  return [self withVerb:@"POST" path:pathPattern];
}

+ (instancetype)PUT:(NSString *)pathPattern
{
  return [self withVerb:@"PUT" path:pathPattern];
}

+ (instancetype)DELETE:(NSString *)pathPattern
{
  return [self withVerb:@"DELETE" path:pathPattern];
}

- (instancetype)respond:(FBRouteSyncHandler)handler
{
  FBRoute_Sync *route = [FBRoute_Sync withVerb:self.verb path:self.path];
  route.handler = handler;
  return route;
}

- (instancetype)respondAsync:(FBRouteAsyncHandler)handler
{
  FBRoute_Async *route = [FBRoute_Async withVerb:self.verb path:self.path];
  route.handler = handler;
  return route;
}

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response
{
  [FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @"") dispatchWithResponse:response];
}

@end
