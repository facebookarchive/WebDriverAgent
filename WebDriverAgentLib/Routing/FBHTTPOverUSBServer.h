/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <Foundation/Foundation.h>

@class RoutingHTTPServer;

NS_ASSUME_NONNULL_BEGIN

/**
 USB service that unwraps HTTP requests sent via USB and dispatches them to HTTP server
 */
@interface FBHTTPOverUSBServer : NSObject

/**
 Service initializer for given 'routingServer' used to dispatch unwrapped requests
 */
- (instancetype)initWithRoutingServer:(RoutingHTTPServer *)routingServer;

/**
 Starts USB service
 */
- (void)startServing;

@end

NS_ASSUME_NONNULL_END
