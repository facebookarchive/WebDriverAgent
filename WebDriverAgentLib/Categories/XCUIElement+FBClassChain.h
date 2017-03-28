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
 This query is similar to xpath, but can only include indexes, predicates and valid class names. Only search by direct children elements of
  the current element is supported. Examples of such requests:
 XCUIElementTypeWindow/XCUIElementTypeButton[3] - select the third child button of the first child window element
 XCUIElementTypeWindow - select all the children windows
 XCUIElementTypeWindow[2] - select the second child window in the hierarchy. Indexing starts at 1
 XCUIElementTypeWindow/XCUIElementTypeAny[3] - select the third child (of any type) of the first child window
 XCUIElementTypeWindow[2]/XCUIElementTypeAny - select all the children of the second child window
 XCUIElementTypeWindow[2]/XCUIElementTypeAny[-2] - select the second last child of the second child window
 One may use '*' (star) character to substitute the universal 'XCUIElementTypeAny' class name
 XCUIElementTypeWindow[`name CONTAINS[cd] "blabla"`] - select all windows, where name attribute starts with "blabla" or "BlAbla"
 XCUIElementTypeWindow[`label BEGINSWITH "blabla"`][-1] - select the last window, where label text begins with "blabla"
 XCUIElementTypeWindow/XCUIElementTypeAny[`value == "bla1" OR label == "bla2"`] - select all children of the first window, where value is "bla1" or label is "bla2"
 XCUIElementTypeWindow[`name == "you're the winner"`]/XCUIElementTypeAny[`visible == 1`] - select all visible children of the first window named "you're the winner"
 Predicate string should be always enclosed into ` characters inside square brackets. Use `` to escape a single ` character inside predicate expression.
 Predicate expression should be always put before the index, but never after it.

 @param classChainQuery valid class chain query string
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be resolved and returned. This will speed up the search significantly if given class name matches multiple nodes in the UI tree
 @return an array of descendants matching given class chain
 @throws FBUnknownAttributeException if any of predicates in the chain contains unknown attribute(s)
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

@end

NS_ASSUME_NONNULL_END
