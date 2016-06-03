/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBHTTPOverUSBClient.h"

#import <peertalk/PTChannel.h>
#import <peertalk/PTUSBHub.h>

#import "FBMacros.h"

#define FBValidateObjectWithClass(object, aClass) \
  if (object && ![object isKindOfClass:aClass]) { \
    [self handleError:FBCreateWebDriverAgentError(@"Invalid object class %@ for %@", [object class], @#object)]; \
    return; \
  }

static NSError *FBCreateWebDriverAgentError(NSString *message, ...) NS_FORMAT_FUNCTION(1,2);

static const in_port_t FBUSBPort = 5000;
static const uint32_t FBUSBFrameType = 100;

@interface FBHTTPOverUSBClient () <PTChannelDelegate>
@property (nonatomic, copy, readonly) NSString *deviceUDID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSString *, WDHTTPOverUSBResponse> *uuidToCallbackMap;
@property (nonatomic, strong) PTChannel *channel;
@end

@implementation FBHTTPOverUSBClient

- (instancetype)initWithDeviceUDID:(NSString *)deviceUDID
{
  self = [super init];
  if (self) {
    _deviceUDID = deviceUDID;
    _uuidToCallbackMap = [NSMutableDictionary dictionary];
  }
  [self startObserving];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startObserving
{
  PTUSBHub *hub = [PTUSBHub new];
  [hub listenOnQueue:dispatch_get_main_queue() onStart:nil onEnd:nil];

  FBWeakify(self);
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserverForName:PTUSBDeviceDidAttachNotification object:hub queue:nil usingBlock:^(NSNotification *note) {
     FBStrongify(self);
     NSString *remoteDeviceUDID = [note userInfo][@"Properties"][@"SerialNumber"];
     if (![remoteDeviceUDID isEqualToString:self.deviceUDID]) {
       return;
     }
     [self connectToUSBDeviceWithID:[note userInfo][@"DeviceID"]];
   }];
  [nc addObserverForName:PTUSBDeviceDidDetachNotification object:hub queue:nil usingBlock:^(NSNotification *note) {
    FBStrongify(self);
    NSString *remoteDeviceUDID = [note userInfo][@"Properties"][@"SerialNumber"];
    if (![remoteDeviceUDID isEqualToString:self.deviceUDID]) {
      return;
    }
    [self.channel cancel];
    self.channel = nil;
  }];
}

- (void)connectToUSBDeviceWithID:(NSNumber *)deviceID
{
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  channel.delegate = self;
  FBWeakify(self);
  [channel connectToPort:FBUSBPort overUSBHub:PTUSBHub.sharedHub deviceID:deviceID callback:^(NSError *error) {
    FBStrongify(self);
    if (error) {
      [self handleError:error];
      return;
    }
    self.channel = channel;
  }];
}

- (BOOL)waitForChannel
{
  NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:15];
  while (!self.channel) {
    if ([timeoutDate timeIntervalSinceDate:[NSDate date]] < 0) {
      return NO;
    }
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  return YES;
}

- (void)dispatchMethod:(NSString *)method endpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters completion:(WDHTTPOverUSBResponse)completion
{
  NSParameterAssert(method);
  NSParameterAssert(endpoint);
  NSParameterAssert(completion);

  NSString *requestUUID = [NSUUID UUID].UUIDString;
  self.uuidToCallbackMap[requestUUID] = completion;

  NSMutableDictionary *requestDictionary =
  @{
    @"uuid" : requestUUID,
    @"method" : method,
    @"path" : endpoint,
  }.mutableCopy;
  if (parameters) {
    requestDictionary[@"parameters"] = parameters;
  }
  NSError *innerError;
  NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:NSJSONWritingPrettyPrinted error:&innerError];
  if (!requestData) {
    [self handleError:innerError];
    return;
  }
  if (![self waitForChannel]) {
    [self handleError:FBCreateWebDriverAgentError(@"Waiting for USB Device %@ timedout!", self.deviceUDID)];
    return;
  }
  [self.channel sendFrameOfType:FBUSBFrameType
                            tag:PTFrameNoTag
                    withPayload:requestData.createReferencingDispatchData
                       callback:^(NSError *sendError) {
                         if (sendError) {
                           [self handleError:sendError];
                         }
                       }
   ];
}

- (void)handleResponseData:(NSData *)data
{
  NSError *innerError;
  NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&innerError];
  if (!response) {
    [self handleError:innerError];
    return;
  }

  if (response && ![response isKindOfClass:NSDictionary.class]) {
    [self handleError:FBCreateWebDriverAgentError(@"Invalid parameter %@", response)];
    return;
  }
  FBValidateObjectWithClass(response, NSDictionary.class);
  NSString *requestUUID = response[@"uuid"];
  FBValidateObjectWithClass(requestUUID, NSString.class);
  FBValidateObjectWithClass(response[@"statusCode"], NSNumber.class);
  FBValidateObjectWithClass(response[@"httpResponse"], NSDictionary.class);
  if (!requestUUID) {
    [self handleError:FBCreateWebDriverAgentError(@"%@", response[@"error"]?: @"Received respond without requestUUID")];
    return;
  }
  [self dispatchHandlerBlockForRequestWithUDID:requestUUID response:response error:nil];
}

- (void)handleError:(NSError *)error
{
  for (NSString *requestUUID in self.uuidToCallbackMap.copy) {
    [self dispatchHandlerBlockForRequestWithUDID:requestUUID response:nil error:error];
  }
}

- (void)dispatchHandlerBlockForRequestWithUDID:(NSString *)requestUUID response:(NSDictionary *)response error:(NSError *)error
{
  WDHTTPOverUSBResponse handler = self.uuidToCallbackMap[requestUUID];
  [self.uuidToCallbackMap removeObjectForKey:requestUUID];
  handler(response, error);
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
  NSData *data = [NSData dataWithContentsOfDispatchData:payload.dispatchData];
  [self handleResponseData:data];
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error
{
  if (self.channel == channel) {
    self.channel = nil;
    if (!error) {
      error = FBCreateWebDriverAgentError(@"Connection finished too early!");
    }
    [self handleError:error];
  }
}

@end

NSError *FBCreateWebDriverAgentError(NSString *format, ...)
{
  va_list argList;
  va_start(argList, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:argList];
  va_end(argList);
  return [NSError errorWithDomain:@"com.facebook.FBWebDriverAgent"
                             code:1
                         userInfo:@{
                                    NSLocalizedDescriptionKey : message
                                    }
          ];
}
