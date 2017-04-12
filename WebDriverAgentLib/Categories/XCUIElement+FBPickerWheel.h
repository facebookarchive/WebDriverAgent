/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCUIElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBPickerWheel)

/**
 Selects the next available option in Picker Wheel
 
 @param error returns error object if there was an error while selecting the
   next picker value
 @return YES if the current option has been successfully switched. Otherwise NO
 */
- (BOOL)fb_selectNextOptionWithError:(NSError **)error;

/**
 Selects the previous available option in Picker Wheel
 
 @param error returns error object if there was an error while selecting the 
   previous picker value
 @return YES if the current option has been successfully switched. Otherwise NO
 */
- (BOOL)fb_selectPreviousOptionWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
