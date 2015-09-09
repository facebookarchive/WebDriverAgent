/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBElementCache;

@interface FBRouteRequest : NSObject
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSDictionary *parameters;
@property (nonatomic, copy, readonly) NSDictionary *arguments;
@property (nonatomic, strong, readonly) FBElementCache *elementCache;

+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments elementCache:(FBElementCache *)elementCache;

@end
