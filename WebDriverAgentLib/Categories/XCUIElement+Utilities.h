/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

@interface XCUIElement (Utilities)

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

@end
