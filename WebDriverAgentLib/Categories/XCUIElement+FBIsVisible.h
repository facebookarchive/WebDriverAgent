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

/*! Whether or not the element is visible.
 The value for this property is equal to
 element snapshot's fb_isVisible property.
 */
@property (atomic, readonly) BOOL fb_isVisible;

@end


@interface XCElementSnapshot (FBIsVisible)

/*! Whether or not the element is visible.
 Set ALTERNATIVE_VISIBILITY_DETECTION environment variable to YES
 if you want the old "hacky" visibility detection algorithm to be used.
 That method gives almost 100% accuracy for visibility detection, but
 can cause unexpected XCTest delays and failures with "Error copying attributes -25202"
 record in logs.
 The current method does not experience such problems, although it is not able to properly
 detect visibility value for UI elements, which are present in the UI tree,
 but are covered by some other elements/views and thus are not really visible.
 See https://github.com/facebook/WebDriverAgent/issues/372 for more details.
*/
@property (atomic, readonly) BOOL fb_isVisible;

@end

NS_ASSUME_NONNULL_END
