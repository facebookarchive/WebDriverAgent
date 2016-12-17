/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import <WebDriverAgentLib/XCElementSnapshot.h>
#import <WebDriverAgentLib/FBElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBUtilities)

/**
 Waits for receiver's frame to become stable with timeout
 */
- (BOOL)fb_waitUntilFrameIsStable;

/**
 Checks if receiver is obstructed by alert
 */
- (BOOL)fb_isObstructedByAlert;

/**
 Checks if receiver obstructs given element

 @param element tested element
 @return YES if receiver obstructs 'element', otherwise NO
 */
- (BOOL)fb_obstructsElement:(XCUIElement *)element;

/**
 Gets the most recent snapshot of the current element. The element will be 
 automatically resolved if the snapshot is not available yet
 
 @return The recent snapshot of the element
 */
- (XCElementSnapshot *)fb_lastSnapshot;

/**
 Categorizes all descendants of the current (self) element based on unique types provided in byTypes set
 
 @param byTypes set of XCUIElementType items
 @return The dictionary, caontaining arrays descendant elements as values categorized by their types as keys.
 An empty dictionary will be returned in case if byTypes set has no items
 */
- (NSDictionary<NSNumber *, NSArray<XCUIElement *> *> *)fb_categorizeDescendants:(NSSet<NSNumber *> *)byTypes;

@end

NS_ASSUME_NONNULL_END
