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

/*! Visible rectange of the element relatively to its ancestors in container window hierarchy.
 Element frame is returned instead if no parent window is detected.
 The result may be equal to CGRectZero if the element is hidden */
@property (readonly, nonatomic) CGRect fb_frameInWindow;

@end


@interface XCElementSnapshot (FBIsVisible)

/*! Whether or not the element is visible */
@property (atomic, readonly) BOOL fb_isVisible;

/*! Visible rectange of the element relatively to its ancestors in container window hierarchy.
 Element frame is returned instead if no parent window is detected.
 The result may be equal to CGRectZero if the element is hidden */
@property (readonly, nonatomic) CGRect fb_frameInWindow;

@end

NS_ASSUME_NONNULL_END
