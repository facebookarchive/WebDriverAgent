/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class XCUIElement;

NS_ASSUME_NONNULL_BEGIN

// This constant defines the size of the element cache, which puts an upper limit
// on the amount of elements which can be stored in the cache.
// Based on the data in https://github.com/facebook/WebDriverAgent/pull/896, each
// element consumes about 100KB of memory; so 1024 elements would consume 100 MB of
// memory.
extern const int ELEMENT_CACHE_SIZE;

@interface FBElementCache : NSObject

/**
 Stores element in cache

 @param element element to store
 @return element's uuid
 */
- (NSString *)storeElement:(XCUIElement *)element;

/**
 Returns cached element

 @param uuid uuid of element to fetch
 @return element
 */
- (nullable XCUIElement *)elementForUUID:(NSString *__nullable)uuid;

@end

NS_ASSUME_NONNULL_END
