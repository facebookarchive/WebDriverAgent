/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWebServer.h"

#import <RoutingHTTPServer/RoutingConnection.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "FBCommandHandler.h"
#import "FBErrorBuilder.h"
#import "FBExceptionHandler.h"
#import "FBHTTPOverUSBServer.h"
#import "FBRouteRequest.h"
#import "FBRuntimeUtils.h"
#import "FBSession.h"
#import "FBUnknownCommands.h"
#import "FBConfiguration.h"
#import "FBLogger.h"

#import "CBXUndefinedCommands.h"

#import "XCUIDevice+FBHelpers.h"

static NSString *const FBServerURLBeginMarker = @"ServerURLHere->";
static NSString *const FBServerURLEndMarker = @"<-ServerURLHere";

@interface FBHTTPConnection : RoutingConnection
@end

@implementation FBHTTPConnection

- (void)handleResourceNotFound
{
  [FBLogger logFmt:@"Received request for %@ which we do not handle", self.requestURI];
  [super handleResourceNotFound];
}

@end


@interface FBWebServer ()
@property (nonatomic, strong) FBExceptionHandler *exceptionHandler;
@property (nonatomic, strong) RoutingHTTPServer *server;
@property (nonatomic, strong) FBHTTPOverUSBServer *USBServer;
@end

@implementation FBWebServer

static FBWebServer *singletonInstance;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [self new];
    });
}

+ (NSArray<Class<FBCommandHandler>> *)collectCommandHandlerClasses
{
  NSArray *handlersClasses = FBClassesThatConformsToProtocol(@protocol(FBCommandHandler));
  NSMutableArray *handlers = [NSMutableArray array];
  for (Class aClass in handlersClasses) {
    if ([aClass respondsToSelector:@selector(shouldRegisterAutomatically)]) {
      if (![aClass shouldRegisterAutomatically]) {
        continue;
      }
    }
    [handlers addObject:aClass];
  }
  return handlers.copy;
}

+ (void)startServing {
    [singletonInstance startServing];
}

+ (void)stop {
    [singletonInstance stop];
}

- (void)startServing
{
  [FBLogger logFmt:@"Built at %s %s", __DATE__, __TIME__];
  self.exceptionHandler = [FBExceptionHandler new];
  [self startHTTPServer];
  if (FBConfiguration.shouldListenOnUSB) {
       [self startUSBServer];
  }
  
    NSTimeInterval interval = 0.1;
    while ([self.server isRunning]) {
        
        // If we are worried about alloc'ing NSDate objects, it might be
        // possible to replace with:
        // CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout_, false);
        NSDate *until = [[NSDate date] dateByAddingTimeInterval:interval];
        [[NSRunLoop mainRunLoop] runUntilDate:until];
        
        // Turning this behavior off because it has some unpleasant side effects.
        //
        // Your tests have completed on a device and the DeviceAgent is still
        // running.  You open Twitter and DeviceAgent auto-allows Twitter access
        // to your Contacts.
        //
        // [self handleSpringBoardAlert];
    }
}

- (void)stop {
    if ([NSThread currentThread] != [NSThread mainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [FBLogger logFmt:@"Shuttind down the server at at %s %s", __DATE__, __TIME__];
            [self.server stop:NO];
            [self.USBServer stop];
        });
    } else {
        [FBLogger logFmt:@"Shuttind down the server at at %s %s", __DATE__, __TIME__];
        [self.server stop:NO];
        [self.USBServer stop];
    }
}

- (void)startHTTPServer
{
  self.server = [[RoutingHTTPServer alloc] init];
  [self.server setRouteQueue:dispatch_get_main_queue()];
    
    [self.server setDefaultHeader:@"Server"
                        value:@"iOSAutomationAgent"];
    [self.server setConnectionClass:[RoutingConnection self]];
    [self.server setType:@"_calabus_._tcp."];
    
    NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *token = [uuid componentsSeparatedByString:@"-"][0];
    NSString *serverName = [NSString stringWithFormat:@"iOSAutomationAgent-%@", token];
    [self.server setName:serverName];
    
    NSDictionary *capabilities =
    @{
      @"name" : [[UIDevice currentDevice] name]
      };
    
    [self.server setTXTRecordDictionary:capabilities];
    
  [self.server setConnectionClass:[FBHTTPConnection self]];

  [self registerRouteHandlers:[self.class collectCommandHandlerClasses]];
  [self registerServerKeyRouteHandlers];

    NSError *error;
  BOOL serverStarted = NO;

    //TODO: Flexible ports
    [self.server setPort:27753];
    /*
     NSRange serverPortRange = FBConfiguration.bindingPortRange;

  for (NSUInteger index = 0; index < serverPortRange.length; index++) {
    NSInteger port = serverPortRange.location + index;
    [self.server setPort:(UInt16)port];

    serverStarted = [self attemptToStartServer:self.server onPort:port withError:&error];
    if (serverStarted) {
      break;
    }

    [FBLogger logFmt:@"Failed to start web server on port %ld with error %@", (long)port, [error description]];
  }
     */
    serverStarted = [self attemptToStartServer:self.server onPort:self.server.port withError:&error];

  if (!serverStarted) {
    [FBLogger logFmt:@"Last attempt to start web server failed with error %@", [error description]];
    abort();
  }
  [FBLogger logFmt:@"%@http://%@:%d%@", FBServerURLBeginMarker, [XCUIDevice sharedDevice].fb_wifiIPAddress ?: @"localhost", [self.server port], FBServerURLEndMarker];
}

- (void)startUSBServer
{
  self.USBServer = [[FBHTTPOverUSBServer alloc] initWithRoutingServer:self.server];
  [self.USBServer startServing];
}

- (BOOL)attemptToStartServer:(RoutingHTTPServer *)server onPort:(NSInteger)port withError:(NSError **)error
{
  server.port = (UInt16)port;
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
    return
    [[[[FBErrorBuilder builder]
       withDescription:description]
      withInnerError:innerError]
     buildError:error];
  }
  return YES;
}

- (void)registerRouteHandlers:(NSArray *)commandHandlerClasses
{
  for (Class<FBCommandHandler> commandHandler in commandHandlerClasses) {
    NSArray *routes = [commandHandler routes];
      if ([commandHandler.class isSubclassOfClass:CBXCommands.class]) {
          NSLog(@"Adding CBXRoutes>>>");
      }
    for (FBRoute *route in routes) {
        if ([commandHandler.class isSubclassOfClass:CBXCommands.class]) {
            NSLog(@"\t%@ %@", route.verb, route.path);
        }
      [self.server handleMethod:route.verb withPath:route.path block:^(RouteRequest *request, RouteResponse *response) {
        NSDictionary *arguments = [NSJSONSerialization JSONObjectWithData:request.body options:NSJSONReadingMutableContainers error:NULL];
        FBRouteRequest *routeParams = [FBRouteRequest
          routeRequestWithURL:request.url
          parameters:request.params
          arguments:arguments ?: @{}
        ];

        [FBLogger verboseLog:routeParams.description];

        @try {
          [route mountRequest:routeParams intoResponse:response];
        }
        @catch (NSException *exception) {
          [self handleException:exception forResponse:response];
        }
      }];
    }
  }
}

- (void)handleException:(NSException *)exception forResponse:(RouteResponse *)response
{
  if ([self.exceptionHandler webServer:self handleException:exception forResponse:response]) {
    return;
  }
  id<FBResponsePayload> payload = FBResponseWithErrorFormat(@"%@\n\n%@", exception.description, exception.callStackSymbols);
  [payload dispatchWithResponse:response];
}

- (void)registerServerKeyRouteHandlers
{
  [self.server get:@"/health" withBlock:^(RouteRequest *request, RouteResponse *response) {
    [response respondWithString:@"I-AM-ALIVE"];
  }];
  [self registerRouteHandlers:@[FBUnknownCommands.class]];
    [self registerRouteHandlers:@[CBXUndefinedCommands.class]];
}

@end
