/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWebServer.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <objc/runtime.h>

#import <RoutingHTTPServer/RoutingConnection.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "FBCommandHandler.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBUnknownCommands.h"
#import "FBWDALogger.h"
#import "FBWDAConstants.h"

NSString *const FBWebServerErrorDomain = @"com.facebook.WebDriverAgent.WebServer";
static NSString *const FBServerURLBeginMarker = @"ServerURLHere->";
static NSString *const FBServerURLEndMarker = @"<-ServerURLHere";

@interface FBHTTPConnection : RoutingConnection
@end

@implementation FBHTTPConnection

- (void)handleResourceNotFound
{
  [FBWDALogger logFmt:@"Received request for %@ which we do not handle", self.requestURI];
  [super handleResourceNotFound];
}

@end


@interface FBWebServer ()
@property (atomic, strong, readwrite) RoutingHTTPServer *server;
@end

@implementation FBWebServer

+ (NSString *)getIPAddress
{
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  int success = getifaddrs(&interfaces);
  if (success != 0) {
    freeifaddrs(interfaces);
    return nil;
  }
  
  NSString *address;
  temp_addr = interfaces;
  while(temp_addr != NULL) {
    if(temp_addr->ifa_addr->sa_family != AF_INET) {
      temp_addr = temp_addr->ifa_next;
      continue;
    }
    NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];
    if(![interfaceName containsString:@"en"]) {
      temp_addr = temp_addr->ifa_next;
      continue;
    }
    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
    break;
  }
  freeifaddrs(interfaces);
  return address;
}

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
  [self.server setDefaultHeader:@"Content-Type" value:@"application/json;charset=UTF-8"];
  [self.server setConnectionClass:[FBHTTPConnection self]];

  [self registerRouteHandlers:[self.class collectCommandHandlerClasses]];
  [self registerServerKeyRouteHandlers];

  NSRange serverPortRange = FBWDAConstants.bindingPortRange;
  NSError *error;
  BOOL serverStarted = NO;

  for (NSInteger index = 0; index < serverPortRange.length; index++) {
    NSInteger port = serverPortRange.location + index;
    [self.server setPort:port];

    serverStarted = [self attemptToStartServer:self.server onPort:port withError:&error];
    if (serverStarted) {
      break;
    }

    [FBWDALogger logFmt:@"Failed to start web server on port %ld with error %@", (long)port, [error description]];
  }

  if (!serverStarted) {
    [FBWDALogger logFmt:@"Last attempt to start web server failed with error %@", [error description]];
    abort();
  }

  NSDictionary *startInfo = @{
    @"port": @([self.server port]),
  };
  [FBWDALogger logFmt:@"WebDriverAgent started on port %hu", [self.server port]];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"WebDriverAgentDidStart" object:nil userInfo:startInfo];
  [FBWDALogger logFmt:@"%@http://%@:%d%@", FBServerURLBeginMarker, [self.class getIPAddress], [self.server port], FBServerURLEndMarker];
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
  for (Class<FBCommandHandler> commandHandler in commandHandlerClasses) {
    NSArray *routes = [commandHandler routes];
    for (FBRoute *route in routes) {
      [self.server handleMethod:route.verb withPath:route.path block:^(RouteRequest *request, RouteResponse *response) {
        FBRouteRequest *routeParams = [FBRouteRequest
          routeRequestWithURL:request.url
          parameters:request.params
          arguments:[NSJSONSerialization JSONObjectWithData:request.body options:0 error:NULL]
          session:[FBSession sessionWithIdentifier:request.params[@"sessionID"]]];

        [FBWDALogger verboseLog:routeParams.description];

        @try {
          [route mountRequest:routeParams intoResponse:response];
        }
        @catch (NSException *exception) {
          [self.exceptionHandler webServer:self handleException:exception forResponse:response];
        }
      }];
    }
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
