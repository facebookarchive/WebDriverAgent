/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRouteRequest.h"

@interface FBRouteRequest ()
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic, copy) NSDictionary *arguments;
@property (nonatomic, strong) FBElementCache *elementCache;
@end

@implementation FBRouteRequest

+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments elementCache:(FBElementCache *)elementCache;
{
  FBRouteRequest *request = [self.class new];
  request.URL = URL;
  request.parameters = parameters;
  request.arguments = arguments;
  request.elementCache = elementCache;
  return request;
}
@end
