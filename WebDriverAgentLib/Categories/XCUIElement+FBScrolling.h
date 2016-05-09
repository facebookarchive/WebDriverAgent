/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCUIElement.h>

@interface XCUIElement (FBScrolling)

- (void)fb_scrollUp;
- (void)fb_scrollDown;
- (void)fb_scrollLeft;
- (void)fb_scrollRight;

- (BOOL)fb_scrollToVisibleWithError:(NSError **)error;

- (BOOL)fb_scrollToVisibleWithNormalizedScrollDistance:(CGFloat)normalizedScrollDistance error:(NSError **)error;

@end
