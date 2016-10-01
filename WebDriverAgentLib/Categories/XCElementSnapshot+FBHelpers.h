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

/**
 The exception happends if the provided XPath expession cannot be compiled because of a syntax error
 */
extern NSString *const XCElementSnapshotInvalidXPathException;
/**
 The exception happends if any internal error is triggered during XPath matching procedure
 */
extern NSString *const XCElementSnapshotXPathQueryEvaluationException;

@interface XCElementSnapshot (FBHelpers)

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

@end

NS_ASSUME_NONNULL_END
