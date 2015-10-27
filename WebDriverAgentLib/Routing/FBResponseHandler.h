/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@protocol FBResponse;
@class FBRequest;

/**
 Protocol defining the handling of a request
 */
@protocol FBResponseHandler <NSObject>

/**
 Handles and returns a response object
 */
- (id<FBResponse>)handleRequest:(FBRequest *)request;

@end
 
typedef id<FBResponse> (^FBResponseHandlerBlock)(FBRequest *request);

/**
 Implementations of Response Handlers.
 */
@interface FBResponseHandler : NSObject

/**
 Creates a Response Handler from a Block.
 */
+ (id<FBResponseHandler>)withBlock:(FBResponseHandlerBlock)block;

/**
 Creates a Response Handler that chains a number of handlers together.
 Breaks out of the chain if any of the handlers in the sequence return a non-ok status.
 The value of the last handler that is executed will be used in the response.
 */
+ (id<FBResponseHandler>)sequence:(NSArray *)handlers;

/**
 Creates a Response Handler that confirms the session is valid, then executes the handler if it is.
 */
+ (id<FBResponseHandler>)requiringSession:(id<FBResponseHandler>)handler;

/**
 Creates a Response Handler for the provided runtime exception
 */
+ (id<FBResponseHandler>)forException:(NSException *)exception;

@end
