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

/**
 Defines directions in which scrolling is possible.
 */
typedef NS_ENUM(NSUInteger, FBXCUIElementScrollDirection) {
  FBXCUIElementScrollDirectionUnknown,
  FBXCUIElementScrollDirectionVertical,
  FBXCUIElementScrollDirectionHorizontal,
};

@interface XCUIElement (FBScrolling)

/**
 Scrolls receiver up by one screen height

 @param distance Normalized <0.0 - 1.0> scroll distance distance
 */
- (void)fb_scrollUpByNormalizedDistance:(CGFloat)distance;

/**
 Scrolls receiver down by one screen height

 @param distance Normalized <0.0 - 1.0> scroll distance distance
 */
- (void)fb_scrollDownByNormalizedDistance:(CGFloat)distance;

/**
 Scrolls receiver left by one screen width

 @param distance Normalized <0.0 - 1.0> scroll distance distance
 */
- (void)fb_scrollLeftByNormalizedDistance:(CGFloat)distance;

/**
 Scrolls receiver right by one screen width

 @param distance Normalized <0.0 - 1.0> scroll distance distance
 */
- (void)fb_scrollRightByNormalizedDistance:(CGFloat)distance;

/**
 Scrolls parent scroll view till receiver is visible.

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_scrollToVisibleWithError:(NSError **)error;

/**
 Scrolls parent scroll view till receiver is visible. Whenever element is invisible it scrolls by normalizedScrollDistance
 in its direction. E.g. if normalizedScrollDistance is equal to 0.5, each step will scroll by half of scroll view's size.

 @param normalizedScrollDistance single scroll step normalized (0.0 - 1.0) distance
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_scrollToVisibleWithNormalizedScrollDistance:(CGFloat)normalizedScrollDistance error:(NSError **)error;

/**
 Scrolls parent scroll view till receiver is visible. Whenever element is invisible it scrolls by normalizedScrollDistance
 in its direction. E.g. if normalizedScrollDistance is equal to 0.5, each step will scroll by half of scroll view's size.

 @param normalizedScrollDistance single scroll step normalized (0.0 - 1.0) distance
 @param scrollDirection the direction in which the scroll view should be scrolled, or FBXCUIElementScrollDirectionUnknown 
 to attempt to determine it automatically
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_scrollToVisibleWithNormalizedScrollDistance:(CGFloat)normalizedScrollDistance scrollDirection:(FBXCUIElementScrollDirection)scrollDirection error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
