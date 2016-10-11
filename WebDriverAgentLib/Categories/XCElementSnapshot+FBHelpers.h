/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCElementSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCElementSnapshot (FBHelpers)

/**
 Returns an array of descendants matching given type
 
 @param type requested descendant type
 @return an array of descendants matching given type
 */
- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type;

/**
 Returns an array of descendants matching given xpath query. This method will always
 throw an exception if there is an error during XPath evaluation, so the returned array
 is nevever expected to be equal to nil
 
 @param xpathQuery requested xpath query. Only XPath v1.0 libxml2-based implementation is supported
 @return an array of descendants matching given xpath query. Empty array will be retuned if
 no matches are found (XPath query should be still valid though)
 */
- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery;

/**
 Returns first (going up element tree) parent that matches given type. If non found returns nil.

 @param type requested parent type
 @return parent element matching given type
 */
- (nullable XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type;

/**
 Returns first (going up element tree) parent that matches one of given types. If non found returns nil.
 
 @param types possible parent types
 @return parent element matching one of given types
 */
- (nullable XCElementSnapshot *)fb_parentMatchingOneOfTypes:(NSArray<NSNumber *> *)types;

/**
 Returns value for given accessibility property identifier.

 @param attribute attribute's accessibility identifier
 @return value for given accessibility property identifier
 */
- (id)fb_attributeValue:(NSNumber *)attribute;

/**
 Method used to determine whether given element matches receiver by comparing it's parameters except frame.

 @param snapshot element's snapshot to compare against
 @return YES, if they match otherwise NO
 */
- (BOOL)fb_framelessFuzzyMatchesElement:(XCElementSnapshot *)snapshot;

/**
 Method used to collect all the unique snapshot types from an array of snapshots.
 
 @param matchingSnapshots array of snpashots
 @return set of unique snapshot types (XCUIElementType items) or an empty set in case the input is empty
 */
+ (NSSet<NSNumber *> *)fb_getUniqueTypes:(NSArray<XCElementSnapshot *> *)matchingSnapshots;

@end

NS_ASSUME_NONNULL_END
