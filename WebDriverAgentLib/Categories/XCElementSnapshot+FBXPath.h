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

@interface XCElementSnapshot (FBXPath)

/**
 Returns an array of descendants matching given type
 
 @param type requested descendant type
 @return an array of descendants matching given type
 */
- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type;

/**
 Returns an array of descendants matching given xpath query
 
 @param xpathQuery requested xpath query
 @return an array of descendants matching given xpath query
 */
- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery;

@end

NS_ASSUME_NONNULL_END
