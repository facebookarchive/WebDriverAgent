/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBHomeboardApplication.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const FBShowAlertButtonName;
extern NSString *const FBShowSheetAlertButtonName;
extern NSString *const FBShowAlertForceTouchButtonName;

/**
 XCTestCase helper class used for integration tests
 */
@interface FBTVIntegrationTestCase : XCTestCase
@property (nonatomic, strong, readonly) XCUIApplication *testedApplication;
@property (nonatomic, strong, readonly, getter = homeboard) FBHomeboardApplication *homeboard;

/**
 Launches application and resets side effects of testing like orientation etc.
 */
- (void)launchApplication;

/**
 Navigates integration app to attributes page
 */
- (void)goToAttributesPage;

/**
 Navigates integration app to alerts page
 */
- (void)goToAlertsPage;

/**
 Navigates integration app to navigation page
 */
- (void)goToNavigationPage;

/**
 Navigates to HeadBoard first page
 */
- (void)goToHeadBoardPage;

/**
 Select tv element in vertical row
 */
- (void)select:(XCUIElement*) element;

/**
 Navigates integration app to scrolling page
 @param showCells whether should navigate to view with cell or plain scrollview
 */
- (void)goToScrollPageWithCells:(BOOL)showCells;

@end

NS_ASSUME_NONNULL_END
