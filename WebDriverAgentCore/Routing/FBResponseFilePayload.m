/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponseFilePayload.h"

#import <RoutingHTTPServer/RouteResponse.h>

@interface FBResponseFilePayload ()

@property (nonatomic, copy, readonly) NSString *path;

@end

@implementation FBResponseFilePayload

- (instancetype)initWithFilePath:(NSString *)path
{
    NSParameterAssert(path);
    if (!path) {
        return nil;
    }

    self = [super init];
    if (self) {
        _path = path;
    }
    return self;
}

- (void)dispatchWithResponse:(RouteResponse *)response
{
  [response respondWithFile:self.path];
}

@end
