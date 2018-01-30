/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <XCTest/XCTest.h>
#import "FBElementCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCUIApplication (FBTouchAction)

/**
 Perform complex touch action in scope of the current application.
 Touch actions are represented as lists of dictionaries with predefined sets of values and keys.
 Each dictionary must contain 'action' key, which is one of the following:
 - 'tap' to perform a single tap
 - 'longPress' to perform long tap
 - 'press' to perform press
 - 'release' to release the finger
 - 'moveTo' to move the virtual finger
 - 'wait' to modify the duration of the preceeding action
 - 'cancel' to cancel the preceeding action in the chain
 Each dictionary can also contain 'options' key with additional parameters dictionary related to the appropriate action.
 
 The following options are mandatory for 'tap', 'longPress', 'press' and 'moveTo' actions:
 - 'x' the X coordinate of the action
 - 'y' the Y coordinate of the action
 - 'element' the corresponding element instance, for which the action is going to be performed
 If only 'element' is set then hit point coordinates of this element will be used.
 If only 'x' and 'y' are set then these will be considered as absolute coordinates.
 If both 'element' and 'x'/'y' are set then these will act as relative element coordinates.
 
 It is also mandatory, that 'release' and 'wait' actions are preceeded with at least one chain item, which contains absolute coordinates, like 'tap', 'press' or 'longPress'. Empty chains are not allowed.
 
 The following additional options are available for different actions:
 - 'tap': 'count' (defines count of taps to be performed in a row; 1 by default)
 - 'longPress': 'duration' (number of milliseconds to hold/move the virtual finger; 500.0 ms by default)
 - 'wait': 'ms' (number of milliseconds to wait for the preceeding action; 0.0 ms by default)
 
 List of lists can be passed there is order to perform multi-finger touch action. Each single actions chain is going to be executed by a separate virtual finger in such case.
 
 @param actions Either array of dictionaries, whose format is described above to peform single-finger touch action or array of array to perform multi-finger touch action.
 @param elementCache Cached elements mapping for the currrent application. The method assumes all elements are already represented by their actual instances if nil value is set
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return YES If the touch action has been successfully performed without errors
 */
- (BOOL)fb_performAppiumTouchActions:(NSArray *)actions elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error;

/**
 Perform complex touch action in scope of the current application.
 
 @param actions Array of dictionaries, whose format is described in W3C spec (https://github.com/jlipps/simple-wd-spec#perform-actions)
 @param elementCache Cached elements mapping for the currrent application. The method assumes all elements are already represented by their actual instances if nil value is set
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return YES If the touch action has been successfully performed without errors
 */
- (BOOL)fb_performW3CTouchActions:(NSArray *)actions elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
