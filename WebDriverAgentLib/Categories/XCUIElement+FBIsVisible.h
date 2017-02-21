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
 The current visibility detection algorithm gives almost 100% accuracy,
 but in some situations it can cause unexpected delays and
 failures with "Error copying attributes -25202" record in logs.
 See https://github.com/facebook/WebDriverAgent/issues/372 for more details.
 
 Set 'useAlternativeVisibilityDetection' setting variable to YES
 using PUT 'wda/settings' API call if you want to use visibility detection based on snapshot frame
 analysis instead. This method does not cause unexpected test freezes,
 although it is not able to properly detect visibility value for some UI elements,
 which are present in the UI tree, but are not really visible in the app interface.
 */
@property (atomic, readonly) BOOL fb_isVisible;

@end

NS_ASSUME_NONNULL_END
