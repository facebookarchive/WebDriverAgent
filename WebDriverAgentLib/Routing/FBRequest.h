/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBElementCache;

/**
 An Value representing the useful information for processing a WebDriver request
 */
@interface FBRequest : NSObject <NSCopying>

/**
 The Full URL of the request.
 */
@property (nonatomic, strong, readonly) NSURL *URL;

/**
 The URL Parameters as a NSDictionary<NSString *, NSString *>
 */
@property (nonatomic, copy, readonly) NSDictionary *parameters;

/**
 The Arguments from the JSON Body of the Request
 */
@property (nonatomic, copy, readonly) NSDictionary *arguments;

/**
 The Element Cache for obtaining pre-cached elements by id
 */
@property (nonatomic, strong, readonly) FBElementCache *elementCache;

/**
 The Session ID from the URL.
 */
@property (nonatomic, copy, readonly) NSString *sessionID;

+ (instancetype)routeRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters arguments:(NSDictionary *)arguments elementCache:(FBElementCache *)elementCache;

@end
