/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponseJSONPayload.h"

#import <RoutingHTTPServer/RouteResponse.h>

@interface FBResponseJSONPayload ()

@property (nonatomic, copy, readonly) NSDictionary *dictionary;

@end

@implementation FBResponseJSONPayload

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  NSParameterAssert(dictionary);
  if (!dictionary) {
    return nil;
  }

  self = [super init];
  if (self) {
    _dictionary = dictionary;
  }
  return self;
}

- (void)dispatchWithResponse:(RouteResponse *)response
{
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.dictionary
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
  NSCAssert(jsonData, @"Valid JSON must be responded, error of %@", error);
  [response setHeader:@"Content-Type" value:@"application/json;charset=UTF-8"];
  [response respondWithData:jsonData];
}

@end
