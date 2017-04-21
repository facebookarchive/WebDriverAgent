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
 
 @param offset the value in range [0.01, 0.5]. It defines how far from picker
   wheel's center the click should happen. The actual distance is culculated by
   multiplying this value to the actual picker wheel height. Too small offset value
   may not change the picker wheel value and too high value may cause the wheel to switch
   two or more values at once. Usually the optimal value is located in range [0.15, 0.3]
 @param error returns error object if there was an error while selecting the
   next picker value
 @return YES if the current option has been successfully switched. Otherwise NO
 */
- (BOOL)fb_selectNextOptionWithOffset:(CGFloat)offset error:(NSError **)error;

/**
 Selects the previous available option in Picker Wheel
 
 @param offset the value in range [0.01, 0.5]. It defines how far from picker
   wheel's center the click should happen. The actual distance is culculated by
   multiplying this value to the actual picker wheel height. Too small offset value
   may not change the picker wheel value and too high value may cause the wheel to switch
   two or more values at once. Usually the optimal value is located in range [0.15, 0.3]
 @param error returns error object if there was an error while selecting the
   previous picker value
 @return YES if the current option has been successfully switched. Otherwise NO
 */
- (BOOL)fb_selectPreviousOptionWithOffset:(CGFloat)offset error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
