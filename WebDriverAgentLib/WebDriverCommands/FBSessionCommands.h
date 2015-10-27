/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "FBCommandHandler.h"

/**
 CRUD Commands for Session endpoints
 */
@interface FBSessionCommands : NSObject <FBCommandHandler>

/**
 The Session ID of the current Session
 */
+ (NSString *)sessionId;

/**
 A Dictionary representing the current session's details.
 */
+ (NSDictionary *)sessionInformation;

@end
