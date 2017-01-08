/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "FBHTTPOverUSBServer.h"

#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import <Peertalk/PTChannel.h>

#import "FBLogger.h"

#define FBValidateObjectWithClass(object, aClass) \
    if (object && ![object isKindOfClass:aClass]) { \
      [self respondWithErrorMessage:[NSString stringWithFormat:@"Invalid object class %@ for %@", [object class], @#object]]; \
      return; \
    }

static const in_port_t FBUSBPort = 5000;
static const uint32_t FBUSBFrameType = 100;

// We can't #include HTTPMessage directly due Pods and FB VendorLib differences
@interface HTTPMessage : NSObject
- (instancetype)initEmptyRequest;
- (void)setBody:(NSData *)body;
@end

@interface FBHTTPOverUSBServer() <PTChannelDelegate>
@property (nonatomic, strong) RoutingHTTPServer *routingServer;
@property (atomic, strong) PTChannel *serverChannel;
@property (atomic, strong) PTChannel *peerChannel;
@end

@implementation FBHTTPOverUSBServer

- (instancetype)initWithRoutingServer:(RoutingHTTPServer *)routingServer
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _routingServer = routingServer;
  return self;
}

- (void)startServing
{
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  __weak __typeof__(self) weakSelf = self;
  [channel listenOnPort:FBUSBPort IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
    if (error) {
      [FBLogger logFmt:@"Failed to listen on USB. %@", error];
      return;
    }
    [FBLogger logFmt:@"Listening on USB"];
    weakSelf.serverChannel = channel;
  }];
}

- (void)stop {
    [self.serverChannel cancel];
}

- (void)handleRequestData:(NSData *)data
{
  NSError *error;
  NSDictionary *requestDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
  if (!requestDictionary) {
    [self respondWithErrorMessage:error.description];
    return;
  }
  FBValidateObjectWithClass(requestDictionary, NSDictionary.class);
  FBValidateObjectWithClass(requestDictionary[@"uuid"], NSString.class);
  FBValidateObjectWithClass(requestDictionary[@"method"], NSString.class);
  FBValidateObjectWithClass(requestDictionary[@"path"], NSString.class);
  FBValidateObjectWithClass(requestDictionary[@"parameters"], NSDictionary.class);

  NSString *uuid = requestDictionary[@"uuid"];
  NSString *method = requestDictionary[@"method"];
  NSString *path = requestDictionary[@"path"];
  NSDictionary *parameters = requestDictionary[@"parameters"];

  HTTPMessage *request = [[HTTPMessage alloc] initEmptyRequest];
  NSData *body = [NSData data];
  if (parameters) {
    body = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    if (!body) {
      [self respondWithErrorMessage:[NSString stringWithFormat:@"Failed to encode request body. %@", error]];
      return;
    }
  }
  [request setBody:body];

  RouteResponse *response = [self.routingServer routeMethod:method withPath:path parameters:(parameters ? : @{}) request:request connection:nil];

  NSData *JSONResponseData = [response.response readDataOfLength:(NSUInteger)response.response.contentLength];
  NSDictionary *httpResponse = [NSJSONSerialization JSONObjectWithData:JSONResponseData options:NSJSONReadingMutableContainers error:&error];
  if (!httpResponse) {
    [self respondWithErrorMessage:[NSString stringWithFormat:@"Failed to decode JSON repsonse. %@", error]];
    return;
  }

  NSDictionary *responseDictionary =
  @{
    @"uuid" : uuid,
    @"statusCode" : @(response.statusCode),
    @"httpResponse" : httpResponse,
  };
  NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseDictionary
                                                         options:NSJSONWritingPrettyPrinted
                                                           error:&error];
  if (!responseData) {
    [self respondWithErrorMessage:[NSString stringWithFormat:@"Failed to encode repsonse. %@", error]];
    return;
  }
  [self respondWithData:responseData];
}

- (void)respondWithErrorMessage:(NSString *)errorMessage
{
  [self respondWithData:[NSJSONSerialization dataWithJSONObject:@{@"error" : errorMessage ?: @"FBHTTPOverUSBServer failed with no error."}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil]];
}

- (void)respondWithData:(NSData *)data
{
  void (^completionBlock)(NSError *) = ^(NSError *innerError){
    if (innerError) {
      [FBLogger logFmt:@"Failed to send USB message. %@", innerError];
    }
  };
  [self.peerChannel sendFrameOfType:FBUSBFrameType
                                tag:PTFrameNoTag
                        withPayload:data.createReferencingDispatchData
                           callback:completionBlock];
}

#pragma mark - PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize
{
  return (type == FBUSBFrameType);
}

- (void)ioFrameChannel:(PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload
{
  if (type != FBUSBFrameType) {
    return;
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self handleRequestData:[NSData dataWithContentsOfDispatchData:payload.dispatchData]];
  });
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error
{
  [FBLogger logFmt:@"USB connection finished. %@", error ?: @""];
  self.peerChannel = nil;
}

- (void)ioFrameChannel:(PTChannel *)channel didAcceptConnection:(PTChannel *)otherChannel fromAddress:(PTAddress *)address
{
  if (self.peerChannel) {
    [self.peerChannel cancel];
  }
  self.peerChannel = otherChannel;
  [FBLogger logFmt:@"USB connection established"];
}

@end
