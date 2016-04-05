/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@protocol FBElement;

@protocol FBElementCache <NSObject>

/**
 * Stores element in cache
 *
 * @param element element to store
 * @return element's index
 */
- (NSUInteger)storeElement:(id <FBElement>)element;

/**
 * Returns cached element
 *
 * @param index index of element to fetch
 * @return element
 */
- (id <FBElement>)elementForIndex:(NSUInteger)index;

@end
