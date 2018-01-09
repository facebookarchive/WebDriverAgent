//
//  FBWebSocket.m
//  WebDriverAgentLib
//
//  Created by Manish Kumar Patwari on 08/01/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FBWebSocket.h"

#import <RoutingHTTPServer/RoutingConnection.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "FBCommandHandler.h"
#import "FBErrorBuilder.h"
#import "FBExceptionHandler.h"
#import "FBRouteRequest.h"
#import "FBRuntimeUtils.h"
#import "FBSession.h"
#import "FBUnknownCommands.h"
#import "FBConfiguration.h"
#import "FBLogger.h"
#import "XCUIDevice+FBHelpers.h"
#import <SocketIO/SocketIO-Swift.h>
#import <JLRoutes/JLRoutes.h>

static NSString *const FBServerURLBeginMarker = @"ServerURLHere->";
static NSString *const FBServerURLEndMarker = @"<-ServerURLHere";

@interface FBSocketConnection : RoutingConnection
@end

@implementation FBSocketConnection

- (void)handleResourceNotFound
{
  [FBLogger logFmt:@"Received request for %@ which we do not handle", self.requestURI];
  [super handleResourceNotFound];
}

@end


@interface FBWebSocket ()
@property (nonatomic, strong) FBExceptionHandler *exceptionHandler;
@property (atomic, assign) BOOL keepAlive;
@property (nonatomic, strong) SocketManager *manager;
@property (nonatomic, strong) NSMutableDictionary *routeDict;
@property (nonatomic, strong) NSDictionary *currentParams;
@end

@implementation FBWebSocket

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

- (void)startSocket
{
  _routeDict = [[NSMutableDictionary alloc] init];
  [FBLogger logFmt:@"Built at %s %s", __DATE__, __TIME__];
  self.exceptionHandler = [FBExceptionHandler new];
  [self startWebSocket];
  
  self.keepAlive = YES;
  NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
  while (self.keepAlive &&
         [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)startWebSocket
{
  NSURL *serverURL = [[NSURL alloc] initWithString:@"http://localhost:8000"];
  self.manager = [[SocketManager alloc] initWithSocketURL:serverURL config:nil];
  SocketIOClient *clientSocket = self.manager.defaultSocket;
  
  [clientSocket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
    NSLog(@"socket connected");
    [clientSocket emit:@"event" with: [[NSArray alloc] initWithObjects:@"hello", nil]];
  }];
  
  [clientSocket on:@"message" callback:^(NSArray* data, SocketAckEmitter* ack) {
    [self socketOnMessageHandler:data andSocketAck:ack];
  }];
  
  [clientSocket connect];
  
  
  [self registerRouteHandlers:[self.class collectCommandHandlerClasses] andClientSocket:clientSocket];
  [self registerServerKeyRouteHandlers: clientSocket];
}

- (void)stopSocket
{
  [FBSession.activeSession kill];
  self.keepAlive = NO;
  //TODO : Stop socket
}

- (void) socketOnMessageHandler: (NSArray*) data andSocketAck: (SocketAckEmitter*) ack
{
//  NSData *requestData = (NSData *) data[0];
//  NSDictionary *arguments = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableContainers error:NULL];
  NSDictionary *arguments = (NSDictionary*) data[0];
  NSString* path = [arguments valueForKey:@"path"];
//  NSDictionary *reqArg = [arguments valueForKey:@"data"];
  NSString *reqData = [arguments valueForKey:@"data"];
  NSDictionary *reqArg = nil;
  if ((reqData != nil) && (![reqData isEqual:[NSNull null]])) {
    NSData *objectData = [reqData dataUsingEncoding:NSUTF8StringEncoding];
    reqArg = [NSJSONSerialization JSONObjectWithData:objectData
                                                           options:NSJSONReadingMutableContainers
                                                             error:NULL];
  }

  NSURL *pathURL = [NSURL URLWithString:path];
  [JLRoutes routeURL:pathURL];
  NSString *routePath = [self.currentParams valueForKey:@"JLRoutePattern"];

  FBRoute* route = [_routeDict valueForKey:routePath];
  if (route == nil) {
    return;
  }
  FBRouteRequest *routeParams = [FBRouteRequest
                                 routeRequestWithURL:pathURL
                                 parameters:self.currentParams
                                 arguments:arguments ? reqArg : @{}
                                 ];

  FBRouteResponse *response = [[FBRouteResponse alloc] initWithSocketAck:ack];
  @try {
    [route mountRequest:routeParams intoResponse:response];
  }
  @catch (NSException *exception) {
    [self handleException:exception forResponse:response];
  }
}


- (void)registerRouteHandlers:(NSArray *)commandHandlerClasses andClientSocket: (SocketIOClient *) clientSocket
{
  for (Class<FBCommandHandler> commandHandler in commandHandlerClasses) {
    NSArray *routes = [commandHandler routes];
    for (FBRoute *route in routes) {
      //if(route.withoutSession) {
        [_routeDict setObject:route forKey:route.path];
        JLRoutes.globalRoutes[route.path] = ^BOOL(NSDictionary *parameters) {
          self.currentParams = parameters;
          return YES;
        };
     // }
    }
  }
}

- (void)handleException:(NSException *)exception forResponse:(FBRouteResponse *)response
{
  if ([self.exceptionHandler handleException:exception forResponse:response]) {
    return;
  }
  id<FBResponsePayload> payload = FBResponseWithErrorFormat(@"%@\n\n%@", exception.description, exception.callStackSymbols);
  [payload dispatchWithResponse:response];
}

- (void)registerServerKeyRouteHandlers: (SocketIOClient*) clientSocket
{
  [clientSocket on:@"/health" callback:^(NSArray* data, SocketAckEmitter* ack) {
    [clientSocket emit:@"I-AM-ALIVE" with: [[NSArray alloc] init]];
  }];
  
  [clientSocket on:@"/wda/shutdown" callback:^(NSArray* data, SocketAckEmitter* ack) {
    [clientSocket emit:@"Shutting down" with: [[NSArray alloc] init]];
  }];
  
  
  [self registerRouteHandlers:@[FBUnknownCommands.class] andClientSocket: clientSocket];
}

@end
