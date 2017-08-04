/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class RouteResponse, RoutingHTTPServer, FBExceptionHandler;
@protocol FBWebServerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 HTTP and USB service wrapper, handling requests and responses
 */
@interface FBWebServer : NSObject

/**
 Server delegate.
 */
@property (weak, nonatomic) id<FBWebServerDelegate> delegate;

/**
 Starts WebDriverAgent service by booting HTTP and USB server
 */
- (void)startServing;

/**
 Stops WebDriverAgent service, shutting down HTTP and USB servers.
 */
- (void)stopServing;

@end

/**
 The protocol allowing the server delegate to handle messages from the server.
 */
@protocol FBWebServerDelegate <NSObject>

/**
 The server requested WebDriverAgent service shutdown.

 @param webServer Server instance.
 */
- (void)webServerDidRequestShutdown:(FBWebServer *)webServer;

@end

NS_ASSUME_NONNULL_END
