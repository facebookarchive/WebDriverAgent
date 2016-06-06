/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCElementSnapshot.h>

extern NSNumber *FB_XCAXAIsVisibleAttribute;
extern NSNumber *FB_XCAXAIsElementAttribute;

@interface XCElementSnapshot (Helpers)

/**
 Returns an array of descendants matching give type

 @param type requested descendant type
 @return an array of descendants matching give type
 */
- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type;

/**
 Returns first (going up element tree) parent that matches given type. If non found returns nil.

 @param type requested parent type
 @return parent element matching given type
 */
- (XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type;

/**
 Returns value for given accessibility property identifier.

 @param attribute attribute's accessibility identifier
 @return value for given accessibility property identifier
 */
- (id)fb_attributeValue:(NSNumber *)attribute;

/**
 Returns snapshot element of main window
 */
- (XCElementSnapshot *)fb_mainWindow;

/**
 Method used to determine whether given element matches receiver by comparing it's parameters except frame.

 @param snapshot element's snapshot to compare against
 @return YES, if they match otherwise NO
 */
- (BOOL)fb_framelessFuzzyMatchesElement:(XCElementSnapshot *)snapshot;

@end
