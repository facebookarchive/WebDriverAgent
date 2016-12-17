/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRouteRequest-Private.h"

@implementation FBRouteRequest

+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments
{
  FBRouteRequest *request = [self.class new];
  request.URL = URL;
  request.parameters = parameters;
  request.arguments = arguments;
  return request;
}

- (NSString *)description
{
  return [NSString stringWithFormat:
    @"Request URL %@ | Params %@ | Arguments %@",
    self.URL,
    self.parameters,
    self.arguments
  ];
}

@end
