/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class XCUIApplication;
@class XCUIElement;

NS_ASSUME_NONNULL_BEGIN

/*! Notification used to notify about requested element being obstructed by alert */
extern NSString *const FBAlertObstructingElementException;

/**
 Alert helper class that abstracts alert handling
 */
@interface FBAlert : NSObject

/**
 Throws FBAlertObstructingElementException
 */
+ (void)throwRequestedItemObstructedByAlertException __attribute__((noreturn));

/**
 Creates alert helper for given application
 */
+ (instancetype)alertWithApplication:(XCUIApplication *)application;

/**
 Determines whether any alert is present
 */
- (BOOL)isPresent;


/**
 Determines whether springboard alert is present
 */
- (BOOL)springboardAlertIsPresent;

/**
 Returns alert's title and description separated by new lines
 */
- (nullable NSString *)text;

/**
 Returns springboard alert's title and description separated by new lines
 */
- (nullable NSString *)springBoardAlertText;

/**
 Accepts alert, if present

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)acceptWithError:(NSError **)error;

- (BOOL)springboardAcceptWithError:(NSError **)error;

/**
 Dismisses alert, if present

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)dismissWithError:(NSError **)error;

- (BOOL)springboardDismissWithError:(NSError **)error;


/**
 Attempt to handle by pressing button with text
 */
- (BOOL)pressSpringboardButtonTitled:(NSString *)title error:(NSError **)error;

/**
 Filters out elements obstructed by alert

 @param elements array of elements we want to filter
 @return elements not obstructed by alert
 */
- (NSArray<XCUIElement *> *)filterObstructedElements:(NSArray<XCUIElement *> *)elements;

/**
 XCUElement that represents alert
 */
- (nullable XCUIElement *)alertElement;

/**
 XCUElement that represents springboard alert
 */
- (nullable XCUIElement *)springboardAlertElement;

@end

NS_ASSUME_NONNULL_END
