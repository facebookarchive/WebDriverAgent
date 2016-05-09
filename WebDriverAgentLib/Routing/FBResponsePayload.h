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

@class FBElementCache;
@class RouteResponse;
@class XCUIElement;

@protocol FBResponsePayload <NSObject>

- (void)dispatchWithResponse:(RouteResponse *)response;

@end

id<FBResponsePayload> FBResponseWithOK(void);
id<FBResponsePayload> FBResponseWithCachedElement(XCUIElement *element, FBElementCache *elementCache);
id<FBResponsePayload> FBResponseWithCachedElements(NSArray<XCUIElement *> *elements, FBElementCache *elementCache);
id<FBResponsePayload> FBResponseWithElementID(NSUInteger elementID);
id<FBResponsePayload> FBResponseWithError(NSError *error);
id<FBResponsePayload> FBResponseWithErrorFormat(NSString *errorFormat, ...) NS_FORMAT_FUNCTION(1,2);
id<FBResponsePayload> FBResponseWithStatus(FBCommandStatus status, id object);
id<FBResponsePayload> FBResponseFileWithPath(NSString *path);

/**
 Factory for constructing payloads
 */
@interface FBResponsePayload : NSObject

+ (id<FBResponsePayload>)ok;
+ (id<FBResponsePayload>)okWith:(id)object;
+ (id<FBResponsePayload>)withElementID:(NSUInteger)elementID;
+ (id<FBResponsePayload>)withError:(NSError *)error;
+ (id<FBResponsePayload>)withErrorFormat:(NSString *)errorFormat, ... NS_FORMAT_FUNCTION(1,2);
+ (id<FBResponsePayload>)withErrorFormat:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(1,0);
+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status;
+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status object:(id)object;
+ (id<FBResponsePayload>)withFileAtPath:(NSString *)path;

@end

