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
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be
 resolved and returned. This will speed up the search significantly if given class name matches multiple
 nodes in the UI tree
 @return an array of descendants matching given class name
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassName:(NSString *)className shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

/**
 Returns an array of descendants matching given accessibility id

 @param accessibilityId requested accessibility id
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be
 resolved and returned. This will speed up the search significantly if given id matches multiple
 nodes in the UI tree
 @return an array of descendants matching given accessibility id
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingIdentifier:(NSString *)accessibilityId shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

/**
 Returns an array of descendants matching given xpath query

 @param xpathQuery requested xpath query
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be
 resolved and returned. This will speed up the search significantly if given xpath matches multiple
 nodes in the UI tree
 @return an array of descendants matching given xpath query
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

/**
 Returns an array of descendants matching given predicate.
 Allowed property names are only these declared in FBElement protocol (property names are received in runtime)
 and their shortcuts (without 'wd' prefix). All other property names are considered as unknown.
 
 @param predicate requested predicate
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be
 resolved and returned. This will speed up the search significantly if given predicate matches multiple
 nodes in the UI tree
 @return an array of descendants matching given predicate
 @throw FBUnknownPredicateKeyException in case the given property name is not declared in FBElement protocol
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

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
