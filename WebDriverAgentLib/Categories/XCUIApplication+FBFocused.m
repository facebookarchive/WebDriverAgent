/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIApplication+FBFocused.h"

@implementation XCUIApplication (FBFocused)

- (XCUIElement*) fb_focusedElement {
  XCUIElementQuery *query = [self descendantsMatchingType:XCUIElementTypeAny];
  return [query elementMatchingPredicate: [NSPredicate predicateWithFormat:@"hasFocus == true"]];
}

@end
