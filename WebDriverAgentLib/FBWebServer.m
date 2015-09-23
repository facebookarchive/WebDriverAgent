/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWebServer.h"

#import <objc/runtime.h>

#import <RoutingHTTPServer/RoutingConnection.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "FBAlertViewCommands.h"
#import "FBCommandHandler.h"
#import "FBElementCache.h"
#import "FBRouteRequest.h"
#import "FBUnknownCommands.h"

extern NSString *kUIAExceptionBadPoint;
extern NSString *kUIAExceptionInvalidElement;
NSString *const FBWebServerErrorDomain = @"com.facebook.WebDriverAgent.WebServer";

@interface FBHTTPConnection : RoutingConnection
@end

@implementation FBHTTPConnection

- (void)handleResourceNotFound
{
  NSLog(@"Received request for %@ which we do not handle", self.requestURI);
  [super handleResourceNotFound];
}

@end


@interface FBWebServer ()
@property (atomic, strong, readwrite) RoutingHTTPServer *server;
@end

@implementation FBWebServer

+ (NSArray *)collectCommandHandlerClasses
{
  Class *classes = NULL;
  NSMutableArray *handlers = [NSMutableArray array];
  int numClasses = objc_getClassList(NULL, 0);
  if (numClasses == 0 ) {
    return nil;
  }

  classes = (__unsafe_unretained Class*)malloc(sizeof(Class) * numClasses);
  numClasses = objc_getClassList(classes, numClasses);
  for (int index = 0; index < numClasses; index++) {
    Class aClass = classes[index];
    if (class_conformsToProtocol(aClass, @protocol(FBCommandHandler))) {
      if ([aClass respondsToSelector:@selector(shouldRegisterAutomatically)]) {
        if (![aClass shouldRegisterAutomatically]) {
          continue;
        }
      }
      [handlers addObject:aClass];
    }
  }
  free(classes);
  return handlers.copy;
}

- (void)startServing
{
  self.server = [[RoutingHTTPServer alloc] init];
  [self.server setRouteQueue:dispatch_get_main_queue()];
  [self.server setDefaultHeader:@"Server" value:@"WebDriverAgent/1.0"];
  [self.server setConnectionClass:[FBHTTPConnection self]];

  [self registerRouteHandlers:[self.class collectCommandHandlerClasses]];
  [self registerServerKeyRouteHandlers];

  NSInteger startPort = 8100;
  NSRange serverPortRange = NSMakeRange(startPort, 100);

  if (NSProcessInfo.processInfo.environment[@"PORT_OFFSET"]) {
    serverPortRange = NSMakeRange(8100 + [NSProcessInfo.processInfo.environment[@"PORT_OFFSET"] integerValue] , 1);
  }

  NSError *error;
  BOOL serverStarted = NO;

  for (NSInteger i = 0; i < serverPortRange.length; i++) {
    NSInteger port = serverPortRange.location + i;
    [self.server setPort:port];

    serverStarted = [self.server start:&error];

    if (serverStarted) {
      break;
    }

    NSLog(@"Failed to start web server with error %@", [error description]);
  }

  if (!serverStarted) {
    NSLog(@"Last attempt to start web server failed with error %@", [error description]);
    abort();
  }

  NSDictionary *startInfo = @{
    @"port": @([self.server port]),
  };
  [[NSNotificationCenter defaultCenter] postNotificationName:@"WebDriverAgentDidStart" object:nil userInfo:startInfo];
}

- (BOOL)attemptToStartServer:(RoutingHTTPServer *)server onPort:(NSInteger)port withError:(NSError **)error
{
  server.port = port;
  NSError *innerError = nil;
  BOOL started = [server start:&innerError];
  if (!started) {
    if (!error) {
      return NO;
    }

    NSString *description = @"Unknown Error when Starting server";
    if ([innerError.domain isEqualToString:NSPOSIXErrorDomain] && innerError.code == EADDRINUSE) {
      description = [NSString stringWithFormat:@"Unable to start web server on port %ld", (long)port];
    }

    *error = [NSError errorWithDomain:FBWebServerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : description, NSUnderlyingErrorKey : innerError}];
    return NO;
  }
  return YES;
}

- (void)registerRouteHandlers:(NSArray *)commandHandlerClasses
{
  FBElementCache *elementCache = [FBElementCache new];
  for (Class<FBCommandHandler> commandHandler in commandHandlerClasses) {
    NSDictionary *routeHandlers = [commandHandler routeHandlers];
    [routeHandlers enumerateKeysAndObjectsUsingBlock:^(NSString *route, FBRouteCommandHandler routeCommandHandler, BOOL *stop) {
        NSArray *components = [route componentsSeparatedByString:@"@"];
        if (components.count != 2) {
          NSLog(@"Routing dictionary key should look like '[GET|PUT|POST|DELETE]@/route' (%@) ", route);
          return;
        }
        [self.server handleMethod:[components[0] uppercaseString] withPath:components[1] block:^(RouteRequest *request, RouteResponse *response) {
            FBRouteRequest *routeParams = [FBRouteRequest routeRequestWithURL:request.url
                                                                   parameters:request.params
                                                                    arguments:[NSJSONSerialization JSONObjectWithData:request.body options:0 error:NULL]
                                                                 elementCache:elementCache
            ];
          @try {
            routeCommandHandler(routeParams,^(id<FBResponsePayload> payload) {
              [payload dispatchWithResponse:response];
            });
          }
          @catch (NSException *exception) {
            if ([exception.name isEqualToString:FBUAlertObstructingElementException]) {
              id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(
                  FBCommandStatusUnexpectedAlertPresent, @"Alert is obstructing view");
              [payload dispatchWithResponse:response];
              return;
            }
            if ([[exception name] isEqualToString:kUIAExceptionInvalidElement]) {
              id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(
                  FBCommandStatusInvalidElementState, [exception description]);
              [payload dispatchWithResponse:response];
              return;
            }
            if ([[exception name] isEqualToString:kUIAExceptionBadPoint]) {
              id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(
                  FBCommandStatusUnhandled, [exception description]);
              [payload dispatchWithResponse:response];
              return;
            }
            id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(
                FBCommandStatusStaleElementReference, [exception description]);
            [payload dispatchWithResponse:response];
          }
        }];
    }];
  }
}

- (void)registerServerKeyRouteHandlers
{
  [self.server get:@"/health" withBlock:^(RouteRequest *request, RouteResponse *response) {
    [response respondWithString:@"I-AM-ALIVE"];
  }];
  [self registerRouteHandlers:@[FBUnknownCommands.class]];
}

@end
