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
 This query is similar to xpath, but can only include indexes, predicates and valid class names. Search by direct children and descendant elements is supported. Examples of direct search requests:
 XCUIElementTypeWindow/XCUIElementTypeButton[3] - select the third child button of the first child window element.
 XCUIElementTypeWindow - select all the children windows.
 XCUIElementTypeWindow[2] - select the second child window in the hierarchy. Indexing starts at 1.
 XCUIElementTypeWindow/XCUIElementTypeAny[3] - select the third child (of any type) of the first child. window
 XCUIElementTypeWindow[2]/XCUIElementTypeAny - select all the children of the second child window.
 XCUIElementTypeWindow[2]/XCUIElementTypeAny[-2] - select the second last child of the second child window.
 One may use '*' (star) character to substitute the universal 'XCUIElementTypeAny' class name.
 XCUIElementTypeWindow[`name CONTAINS[cd] "blabla"`] - select all windows, where name attribute starts with "blabla" or "BlAbla".
 XCUIElementTypeWindow[`label BEGINSWITH "blabla"`][-1] - select the last window, where label text begins with "blabla".
 XCUIElementTypeWindow/XCUIElementTypeAny[`value == "bla1" OR label == "bla2"`] - select all children of the first window, where value is "bla1" or label is "bla2".
 XCUIElementTypeWindow[`name == "you're the winner"`]/XCUIElementTypeAny[`visible == 1`] - select all visible children of the first window named "you're the winner".
 XCUIElementTypeWindow/XCUIElementTypeTable/XCUIElementTypeCell[`visible == 1`][$type == XCUIElementTypeImage AND name == 'bla'$]/XCUIElementTypeTextField - select a text field, which is a direct child of a visible table cell, which has at least one descendant image with identifier 'bla'.
 Predicate string should be always enclosed into ` or $ characters inside square brackets. Use `` or $$ to escape a single ` or $ character inside predicate expression.
 Single backtick means the predicate expression is applied to the current children. It is the direct alternative of matchingPredicate: query selector.
 Single dollar sign means the predicate expression is applied to all the descendants of the current element(s). It is the direct alternative of containingPredicate: query selector.
 Predicate expression should be always put before the index, but never after it. All predicate expressions are executed in the same exact order, which is set in the chain query.
 It is not recommended to set explicit indexes for intermediate chain elements, because it slows down the lookup speed.
 
 Indirect descendant search requests are pretty similar to requests above:
 ** /XCUIElementTypeCell[`name BEGINSWITH "A"`][-1]/XCUIElementTypeButton[10] - select the 10-th child button of the very last cell in the tree, whose name starts with 'A'.
 ** /XCUIElementTypeCell[`name BEGINSWITH "B"`] - select all cells in the tree, where name starts with 'B'
 ** /XCUIElementTypeCell[`name BEGINSWITH "C"`]/XCUIElementTypeButton[10] - select the 10-th child button of the first cell in the tree, whose name starts with 'C' and which has at least ten direct children of type XCUIElementTypeButton.
 ** /XCUIElementTypeCell[`name BEGINSWITH "D"`]/ ** /XCUIElementTypeButton - select the all descendant buttons of the first cell in the tree, whose name starts with 'D'.

 Double star and slash is the marker of the fact, that the next following item is the descendant of the previous chain item, rather than its child.
 
 The matching result is similar to what XCTest's children... and descendants... selector calls of XCUIElement class instances produce when combined into a chain.
 
 @param classChainQuery valid class chain query string
 @param shouldReturnAfterFirstMatch set it to YES if you want only the first found element to be resolved and returned. 
   This will speed up the search significantly if the given chain matches multiple nodes in the UI tree
 @return an array of descendants matching given class chain
 @throws FBUnknownAttributeException if any of predicates in the chain contains unknown attribute(s)
 */
- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassChain:(NSString *)classChainQuery shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch;

@end

NS_ASSUME_NONNULL_END
