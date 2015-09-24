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
#import "FBResponsePayload.h"

#define UIAClassString(class_) \
@(((void)(NO && ([class_ class], NO)), # class_))

@class FBRouteRequest;

id<FBResponsePayload> FBResponseDictionaryWithOK(void);
id<FBResponsePayload> FBResponseDictionaryWithElementID(NSUInteger elementID);
id<FBResponsePayload> FBResponseDictionaryWithStatus(FBCommandStatus status, id object);
id<FBResponsePayload> FBResponseFileWithPath(NSString *path);

typedef void (^FBRouteResponseCompletion)(id<FBResponsePayload>);
typedef void (^FBRouteCommandHandler)(FBRouteRequest *arguments, FBRouteResponseCompletion completionHandler);

@protocol FBCommandHandler <NSObject>

/**
 * Should return map of FBRouteCommandHandler block with keys as supported routes
 * Key should be defined as '[GET|PUT|POST|DELETE]@/route'
 *
 * @return map map route to FBRouteCommandHandler
 */
+ (NSDictionary *)routeHandlers;

@optional
/**
 * @return BOOL deciding if class should be added to route handlers automatically, default (if not implemented) is YES
 */
+ (BOOL)shouldRegisterAutomatically;

@end
