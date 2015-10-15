/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRoute.h"

#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "FBAlertViewCommands.h"
#import "FBCommandHandler.h"
#import "FBElementCache.h"
#import "FBResponse.h"
#import "FBRequest.h"
#import "FBRequest.h"
#import "FBUnknownCommands.h"
#import "FBWDAConstants.h"
#import "FBWDALogger.h"

@interface FBRoute ()

@property (nonatomic, copy, readwrite) NSString *verb;
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, assign, readwrite) BOOL requiresSession;
@property (nonatomic, strong, readwrite) id<FBResponseHandler> handler;

@end

@implementation FBRoute

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _requiresSession = YES;
  return self;
}

+ (instancetype)withVerb:(NSString *)verb
{
  FBRoute *route = [self new];
  route.verb = verb;
  return route;
}

+ (instancetype)withVerb:(NSString *)verb path:(NSString *)pathPattern
{
  return [[self withVerb:verb] withPath:pathPattern];
}

+ (instancetype)GET
{
  return [self withVerb:@"GET"];
}

+ (instancetype)GET:(NSString *)pathPattern
{
  return [self withVerb:@"GET" path:pathPattern];
}

+ (instancetype)POST
{
  return [self withVerb:@"POST"];
}

+ (instancetype)POST:(NSString *)pathPattern
{
  return [self withVerb:@"POST" path:pathPattern];
}

+ (instancetype)PUT
{
  return [self withVerb:@"PUT"];
}

+ (instancetype)PUT:(NSString *)pathPattern
{
  return [self withVerb:@"PUT" path:pathPattern];
}

+ (instancetype)DELETE
{
  return [self withVerb:@"DELETE"];
}

+ (instancetype)DELETE:(NSString *)pathPattern
{
  return [self withVerb:@"DELETE" path:pathPattern];
}

- (instancetype)sessionNotRequired
{
  self.requiresSession = NO;
  return self;
}

- (instancetype)respondWith:(id<FBResponseHandler>)handler
{
  self.handler = handler;
  return self;
}

- (instancetype)respond:(FBResponseHandlerBlock)block
{
  self.handler = [FBResponseHandler withBlock:block];
  return self;
}

- (instancetype)applyToServer:(RoutingHTTPServer *)server withElementCache:(FBElementCache *)cache
{
  if (!self.requiresSession) {
    [self applyToServer:server path:self.path verb:self.verb elementCache:cache];
  }

  NSString *path = [@"/session/:sessionID" stringByAppendingPathComponent:self.path];
  [self applyToServer:server path:path verb:self.verb elementCache:cache];
  return self;
}

#pragma mark Private

- (void)mountRequest:(FBRequest *)request intoResponse:(RouteResponse *)routeResponse
{
  NSParameterAssert(self.handler);

  id<FBResponseHandler> handler = self.requiresSession && FBWDAConstants.validatesSession ? [FBResponseHandler requiringSession:self.handler] : self.handler;
  id<FBResponse> response = nil;
  @try {
    response = [handler handleRequest:request];
  }
  @catch (NSException *exception) {
    [FBWDALogger verboseLogFmt:@"Exception during response handling: %@", exception];
    response = [[FBResponseHandler forException:exception] handleRequest:request];
  }
  @finally {
    response = response ?: [FBResponse withStatus:FBCommandStatusUnhandled];
  }

  [response dispatchWithResponse:routeResponse];
}

- (void)applyToServer:(RoutingHTTPServer *)server path:(NSString *)path verb:(NSString *)verb elementCache:(FBElementCache *)cache
{
  [server handleMethod:verb withPath:path block:^(RouteRequest *request, RouteResponse *response) {
    FBRequest *routeParams = [FBRequest
      routeRequestWithURL:request.url
      parameters:request.params
      arguments:[NSJSONSerialization JSONObjectWithData:request.body options:0 error:NULL]
      elementCache:cache];

    [FBWDALogger verboseLog:routeParams.description];
    [self mountRequest:routeParams intoResponse:response];
  }];
}

- (instancetype)withPath:(NSString *)path
{
  self.path = path;
  return self;
}

@end
