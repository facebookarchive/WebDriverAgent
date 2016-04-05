/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <UIAWebDriverAgentLib/FBElementCache.h>
#import <UIAWebDriverAgentLib/UIAElement+WebDriverAttributes.h>

@class UIAElement;

@interface FBUIAElementCache : NSObject <FBElementCache>

/**
 * Stores element in cache
 *
 * @param element element to store
 * @return element's index
 */
- (NSUInteger)storeElement:(UIAElement *)element;

/**
 * Returns cached element
 *
 * @param index index of element to fetch
 * @return element
 */
- (UIAElement *)elementForIndex:(NSUInteger)index;

@end
