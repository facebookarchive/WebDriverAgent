/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTWebDriverAgentLib/XCUIElement.h>

#if TARGET_OS_IPHONE

@interface XCUIElement (FBScrolling)

- (void)scrollUp;
- (void)scrollDown;
- (void)scrollLeft;
- (void)scrollRight;

- (void)scrollToVisible;

@end

#endif
