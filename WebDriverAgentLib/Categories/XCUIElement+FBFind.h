/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBFind)

/**
 Returns an array of descendants matching given class name

 @param className requested class name
 @return an array of descendants matching given class name
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassName:(NSString *)className;

/**
 Returns an array of descendants matching given xui locator

 @param locator requested xui locator
 @return an array of descendants matching given cell index
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingXui:(NSString *)locator;

/**
 Returns an array of descendants matching given accessibility id

 @param accessibilityId requested accessibility id
 @return an array of descendants matching given accessibility id
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingIdentifier:(NSString *)accessibilityId;

/**
 Returns an array of descendants matching given xpath query

 @param xpathQuery requested xpath query
 @return an array of descendants matching given xpath query
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery;

/**
 Returns an array of descendants matching given predicate

 @param predicate requested predicate
 @return an array of descendants matching given predicate
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate;

/**
 Returns an array of descendants with property matching given value

 @param property requested property name
 @param value requested value of the property
 @param partialSearch determines whether it should be exact or partial match
 @return an array of descendants with property matching given value
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingProperty:(NSString *)property value:(NSString *)value partialSearch:(BOOL)partialSearch;

@end

NS_ASSUME_NONNULL_END
