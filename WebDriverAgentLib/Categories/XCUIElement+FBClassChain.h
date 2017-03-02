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

/*! Exception used to notify about invalid class chain query */
extern NSString *const FBClassChainQueryParseException;

@interface XCUIElement (FBClassChain)

/**
 Returns an array of descendants matching given class chain query.
 This query is very similar to xpath, but can only include indexes and valid class names. Only search by direct children elements of
  the current element is supported. Examples of such requests:
 XCUIElementTypeWindow/XCUIElementTypeButton[3] - select the third child button of the first child window element
 XCUIElementTypeWindow - select all the children windows
 XCUIElementTypeWindow[2] - select the second child window in the hierarchy. Indexing starts at 1
 XCUIElementTypeWindow/XCUIElementTypeAny[3] - select the third child (of any type) of the first child window
 XCUIElementTypeWindow[2]/XCUIElementTypeAny - select all the children of the second child window
 XCUIElementTypeWindow[2]/XCUIElementTypeAny[-2] - select the second last child of the second child window
 One may use '*' (star) character to substitute the universal 'XCUIElementTypeAny' class name
 
 @param classChainQuery valid class chain query string
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be resolved and returned. This will speed up the search significantly if given class name matches multiple nodes in the UI tree
 @return an array of descendants matching given class chain
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

@end

NS_ASSUME_NONNULL_END
