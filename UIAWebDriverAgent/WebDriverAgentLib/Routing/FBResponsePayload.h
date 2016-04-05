/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "FBCommandStatus.h"

@class RouteResponse;

@protocol FBResponsePayload <NSObject>

- (void)dispatchWithResponse:(RouteResponse *)response;

@end

id<FBResponsePayload> FBResponseDictionaryWithOK(void);
id<FBResponsePayload> FBResponseDictionaryWithElementID(NSUInteger elementID);
id<FBResponsePayload> FBResponseDictionaryWithStatus(FBCommandStatus status, id object);
id<FBResponsePayload> FBResponseFileWithPath(NSString *path);

/**
 Factory for constructing payloads
 */
@interface FBResponsePayload : NSObject

+ (id<FBResponsePayload>)ok;
+ (id<FBResponsePayload>)okWith:(id)object;
+ (id<FBResponsePayload>)withElementID:(NSUInteger)elementID;
+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status;
+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status object:(id)object;
+ (id<FBResponsePayload>)withFileAtPath:(NSString *)path;

@end

