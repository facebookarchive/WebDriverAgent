//
//  FBRouteResponse.h
//  WebDriverAgentLib
//
//  Created by SHUBHANKAR YASH on 08/01/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RoutingHTTPServer/RouteResponse.h>
#import <SocketIO/SocketIO-Swift.h>

@interface FBRouteResponse: NSObject

@property (strong, nonatomic) RouteResponse* response;
@property (strong, nonatomic) SocketAckEmitter* socketAck;

- (id)initWithRouteResponse:(RouteResponse *)response;
- (id)initWithSocketAck:(SocketAckEmitter *)socketAck;
- (void)setHeader:(NSString *)field value:(NSString *)value;
- (void)respondWithString:(NSString *)string;
- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)respondWithData:(NSData *)data;
- (void)respondWithFile:(NSString *)path;
- (void)respondWithFile:(NSString *)path async:(BOOL)async;


@end
