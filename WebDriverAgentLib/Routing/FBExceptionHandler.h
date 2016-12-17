/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <WebDriverAgentLib/FBWebServer.h>

NS_ASSUME_NONNULL_BEGIN

/*! Exception used to notify about missing session */
extern NSString *const FBSessionDoesNotExistException;

/*! Exception used to notify about application deadlock */
extern NSString *const FBApplicationDeadlockDetectedException;

/*! Exception used to notify about unknown attribute */
extern NSString *const FBElementAttributeUnknownException;

/*! Exception used to notify about invalid argument */
extern NSString *const FBInvalidArgumentException;

/**
 Class used to handle exceptions raised by command handlers
 */
@interface FBExceptionHandler : NSObject

/**
 Handles 'exception' for 'webServer' raised while handling 'response'

 @param webServer server for which exception is handled
 @param exception exception that needs handling
 @param response response related to that exception
 @return YES, if exception was handled, otherwise NO
 */
- (BOOL)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response;

@end

NS_ASSUME_NONNULL_END
