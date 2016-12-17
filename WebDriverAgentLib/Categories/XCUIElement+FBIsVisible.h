/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCElementSnapshot.h>
#import <WebDriverAgentLib/XCUIElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBIsVisible)

/*! Whether or not the element is visible */
@property (atomic, readonly) BOOL fb_isVisible;

@end


@interface XCElementSnapshot (FBIsVisible)

/*! Whether or not the element is visible */
@property (atomic, readonly) BOOL fb_isVisible;

@end

NS_ASSUME_NONNULL_END
