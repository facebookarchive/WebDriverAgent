/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

extern NSString *const FBWebServerErrorDomain;

@class RouteResponse;
@protocol FBWebServerExceptionHandler, FBElementCache;

@interface FBWebServer : NSObject
@property (nonatomic, strong) id <FBWebServerExceptionHandler> exceptionHandler;

- (void)startServing;

@end


@protocol FBWebServerExceptionHandler <NSObject>

- (void)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response;

@end

