/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRequest.h"

@interface FBRequest ()

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic, copy) NSDictionary *arguments;
@property (nonatomic, strong) FBElementCache *elementCache;

@end

@implementation FBRequest

+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments elementCache:(FBElementCache *)elementCache;
{
  FBRequest *request = [self.class new];
  request.URL = URL;
  request.parameters = parameters;
  request.arguments = arguments;
  request.elementCache = elementCache;
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

#pragma mark Accessors

- (NSString *)sessionID
{
  return self.parameters[@"sessionID"];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  FBRequest *request = [self.class new];
  request.URL = self.URL;
  request.parameters = request.parameters;
  request.arguments = request.arguments;
  request.elementCache = request.elementCache;
  return request;
}

@end
