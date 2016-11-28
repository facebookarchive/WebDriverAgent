/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <WebDriverAgentLib/FBElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBElementUtils : NSObject

/**
 Function that returns property name defined by FBElement protocol for given WebDriver Spec property name
 
 @param name WebDriver Spec property name
 @return the corresponding property name
 */
+ (NSString *)fb_attributeNameForAttributeName:(NSString *)name;

/**
 Function used to collect all the unique element types from an array of elements.
 
 @param elements array of elements
 @return set of unique element types (XCUIElementType items) or an empty set in case the input is empty
 */
+ (NSSet<NSNumber *> *)fb_getUniqueElementsTypes:(NSArray<id<FBElement>> *)elements;

@end

NS_ASSUME_NONNULL_END
