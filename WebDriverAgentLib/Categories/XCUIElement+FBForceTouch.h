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

@interface XCUIElement (FBForceTouch)

/**
 Waits for element to become stable (not move) and performs sync force touch on element
 
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @param pressure The pressure of the force touch – valid values are [0, touch.maximumPossibleForce]
 @param duration The duration of the gesture
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_forceTouchWithPressure:(double)pressure duration:(double)duration error:(NSError **)error;

/**
 Waits for element to become stable (not move) and performs sync force touch on element
 
 @param relativeCoordinate hit point coordinate relative to the current element position
 @param pressure The pressure of the force touch – valid values are [0, touch.maximumPossibleForce]
 @param duration The duration of the gesture
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_forceTouchCoordinate:(CGPoint)relativeCoordinate pressure:(double)pressure duration:(double)duration error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
