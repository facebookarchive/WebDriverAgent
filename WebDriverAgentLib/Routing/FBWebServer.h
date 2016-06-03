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

/**
 HTTP and USB service wrapper, that handel's requests and responses
 */
@interface FBWebServer : NSObject
@property (nonatomic, strong, readonly) RoutingHTTPServer *server;
@property (nonatomic, strong) FBExceptionHandler *exceptionHandler;

/**
 Starts WebDriverAgent service by booting HTTP and USB server
 */
- (void)startServing;

/**
 Method used to notify service about app deadlock
 */
- (void)handleAppDeadlockDetection;

@end
