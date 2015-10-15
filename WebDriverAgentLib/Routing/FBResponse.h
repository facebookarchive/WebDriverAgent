/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "FBCommandStatus.h"

@class RouteResponse;

/**
 Bridges data returned from Response handlers to RouteResponse
 */
@protocol FBResponse <NSObject>

/**
 Mounts the Respone into the RouteResponse object
 */
- (void)dispatchWithResponse:(RouteResponse *)response;

/**
 YES if the Response indicates that the Response represents a success, NO otherwise
 */
- (BOOL)isSuccessfulStatus;

@end

/**
 Factory for responses.
 */
@interface FBResponse : NSObject

+ (id<FBResponse>)ok;
+ (id<FBResponse>)okWith:(id)object;
+ (id<FBResponse>)withElementID:(NSUInteger)elementID;
+ (id<FBResponse>)withStatus:(FBCommandStatus)status;
+ (id<FBResponse>)withStatus:(FBCommandStatus)status object:(id)object;
+ (id<FBResponse>)withFileAtPath:(NSString *)path;

@end

