/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBSpringboardApplication.h"
#import "FBTestMacros.h"
#import "FBIntegrationTestCase.h"
#import "FBConfiguration.h"
#import "FBMacros.h"
#import "FBRunLoopSpinner.h"
#import "XCUIDevice+FBRotation.h"
#import "XCUIElement.h"
#import "XCUIElement+FBIsVisible.h"

NSString *const FBShowAlertButtonName = @"Create App Alert";
NSString *const FBShowSheetAlertButtonName = @"Create Sheet Alert";

@interface FBIntegrationTestCase ()
@property (nonatomic, strong) XCUIApplication *testedApplication;
@property (nonatomic, strong) FBSpringboardApplication *springboard;
@end

@implementation FBIntegrationTestCase

- (void)setUp
{
  [super setUp];
  [FBConfiguration disableRemoteQueryEvaluation];
  [FBConfiguration disableAttributeKeyPathAnalysis];
  self.continueAfterFailure = NO;
  self.springboard = [FBSpringboardApplication fb_springboard];
  self.testedApplication = [XCUIApplication new];
}

- (void)launchApplication
{
  [self.testedApplication launch];
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"Alerts"].fb_isVisible);
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

  // Reset orientation
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:UIDeviceOrientationPortrait];
}

- (void)goToAttributesPage
{
  [self.testedApplication.buttons[@"Attributes"] tap];
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"Button"].fb_isVisible);
}

- (void)goToAlertsPage
{
  [self.testedApplication.buttons[@"Alerts"] tap];
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[FBShowAlertButtonName].fb_isVisible);
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[FBShowSheetAlertButtonName].fb_isVisible);
}

- (void)goToSpringBoardFirstPage
{
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  FBAssertWaitTillBecomesTrue([FBSpringboardApplication fb_springboard].icons[@"Safari"].exists);
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  FBAssertWaitTillBecomesTrue([FBSpringboardApplication fb_springboard].icons[@"Calendar"].fb_isVisible);
}

- (void)goToSpringBoardExtras
{
  [self goToSpringBoardFirstPage];
  [self.springboard swipeLeft];
  FBAssertWaitTillBecomesTrue(self.springboard.icons[@"Extras"].fb_isVisible);
}

- (void)goToSpringBoardDashboard
{
  [self goToSpringBoardFirstPage];
  [self.springboard swipeRight];
  NSPredicate *predicate =
    [NSPredicate predicateWithFormat:
     @"%K IN %@",
     FBStringify(XCUIElement, identifier),
     @[@"SBSearchEtceteraIsolatedView", @"SpotlightSearchField"]
   ];
  FBAssertWaitTillBecomesTrue([[self.springboard descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate].fb_isVisible);
  FBAssertWaitTillBecomesTrue(!self.springboard.icons[@"Calendar"].fb_isVisible);
}

- (void)goToScrollPageWithCells:(BOOL)showCells
{
  [self.testedApplication.buttons[@"Scrolling"] tap];
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"TableView"].fb_isVisible);
  [self.testedApplication.buttons[showCells ? @"TableView": @"ScrollView"] tap];
  FBAssertWaitTillBecomesTrue(self.testedApplication.staticTexts[@"3"].fb_isVisible);
}

@end
