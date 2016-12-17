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
