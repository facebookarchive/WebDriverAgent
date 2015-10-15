/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "FBResponseHandler.h"

@protocol FBResponse;
@class FBElementCache;
@class FBRequest;
@class RouteResponse;
@class RoutingHTTPServer;

/**
 Describes the format of a handled URL route.
 */
@interface FBRoute : NSObject

+ (instancetype)GET;
+ (instancetype)GET:(NSString *)pathPattern;

+ (instancetype)POST;
+ (instancetype)POST:(NSString *)pathPattern;

+ (instancetype)PUT;
+ (instancetype)PUT:(NSString *)pathPattern;

+ (instancetype)DELETE;
+ (instancetype)DELETE:(NSString *)pathPattern;

/**
 Removes the Session ID requirement on the route.
 With a `pathPattern` of '/foo', the two endpoints are made: '/session/sessionID/foo' and '/foo'
 */
- (instancetype)sessionNotRequired;

/**
 Replaces the Response Handler with the provided handler.
 */
- (instancetype)respondWith:(id<FBResponseHandler>)handler;

/**
 Replaces the Response Handler using the provided block.
 */
- (instancetype)respond:(FBResponseHandlerBlock)block;

/**
 Adds the Route to the provided server.
 */
- (instancetype)applyToServer:(RoutingHTTPServer *)server withElementCache:(FBElementCache *)cache;

@end
