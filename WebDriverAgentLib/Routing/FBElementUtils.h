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
#import "XCAccessibilityElement.h"

NS_ASSUME_NONNULL_BEGIN

/*! Notification used to notify about unknown attribute name */
extern NSString *const FBUnknownAttributeException;

@interface FBElementUtils : NSObject

/**
 Returns property name defined by FBElement protocol for the given WebDriver Spec property name.
 Check the FBElement protocol to get list of supported attributes.
 This method also supports shortcuts, like wdName == name, wdValue == value.
 In case the corresponding attribute has a getter defined then the name of the getter witll be returned instead,
 which makes this method compatible with KVO lookup
 
 @param name WebDriver Spec property name
 @return the corresponding property name
 @throws FBUnknownAttributeException if there is no matching attribute defined in FBElement protocol
 */
+ (NSString *)wdAttributeNameForAttributeName:(NSString *)name;

/**
 Collects all the unique element types from an array of elements.
 
 @param elements array of elements
 @return set of unique element types (XCUIElementType items) or an empty set in case the input is empty
 */
+ (NSSet<NSNumber *> *)uniqueElementTypesWithElements:(NSArray<id<FBElement>> *)elements;

/**
 Returns mapping of all possible FBElement protocol properties aliases
 
 @return dictionary of matching property aliases with their real names as values or getter method names if exist
 for KVO lookup
 */
+ (NSDictionary<NSString *, NSString *> *)wdAttributeNamesMapping;

/**
 Gets the unique identifier of the particular XCAccessibilityElement instance.
 
 @param element accessiblity element instance
 @return the unique element identifier
 */
+ (NSString *)uidWithAccessibilityElement:(XCAccessibilityElement *)element;

@end

NS_ASSUME_NONNULL_END
