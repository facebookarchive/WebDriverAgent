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

typedef id<FBResponsePayload> (^FBRouteSyncHandler)(FBRouteRequest *request);

@interface FBRoute : NSObject

+ (instancetype)GET:(NSString *)pathPattern;
+ (instancetype)POST:(NSString *)pathPattern;
+ (instancetype)PUT:(NSString *)pathPattern;
+ (instancetype)DELETE:(NSString *)pathPattern;

- (instancetype)respond:(FBRouteSyncHandler)handler;

@property (nonatomic, copy, readonly) NSString *verb;
@property (nonatomic, copy, readonly) NSString *path;

- (void)mountRequest:(FBRouteRequest *)request intoResponse:(RouteResponse *)response;

@end
