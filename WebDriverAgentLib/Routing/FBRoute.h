/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@protocol FBResponsePayload;
@class FBRouteRequest;
@class RouteResponse;

NS_ASSUME_NONNULL_BEGIN

typedef __nonnull id<FBResponsePayload> (^FBRouteSyncHandler)(FBRouteRequest *request);

/**
 Class that represents route
 */
@interface FBRoute : NSObject

/*! Route's verb (eg. POST, GET, DELETE) */
@property (nonatomic, copy, readonly) NSString *verb;

/*! Route's path */
@property (nonatomic, copy, readonly) NSString *path;

/**
 Convenience constructor for GET route with given pathPattern
 */
+ (instancetype)GET:(NSString *)pathPattern;

/**
 Convenience constructor for POST route with given pathPattern
 */
+ (instancetype)POST:(NSString *)pathPattern;

/**
 Convenience constructor for PUT route with given pathPattern
 */
+ (instancetype)PUT:(NSString *)pathPattern;

/**
 Convenience constructor for DELETE route with given pathPattern
 */
+ (instancetype)DELETE:(NSString *)pathPattern;

/**
 Chain-able constructor that handles response with given FBRouteSyncHandler block
 */
- (instancetype)respondWithBlock:(FBRouteSyncHandler)handler;

/**
 Chain-able constructor that handles response with given FBRouteSyncHandler block
 */
- (instancetype)respondWithTarget:(id)target action:(SEL)selector;

/**
 Chain-able constructor for route that does NOT require session
 */
- (instancetype)withoutSession;

/**
 Dispatches response for request
 */
- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response;

@end

NS_ASSUME_NONNULL_END
