/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBTvIntegrationTestCase.h"

#import "FBSpringboardApplication.h"
#import "FBTestMacros.h"
#import "FBTvIntegrationTestCase.h"
#import "FBConfiguration.h"
#import "FBMacros.h"
#import "FBRunLoopSpinner.h"
#import "XCUIDevice+FBRotation.h"
#import "XCUIElement.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIApplication+FBFocused.h"
//#import "XCUIElement+FBTVInteract.h"
//#import "XCUIElement+FBFocuse.h"


NSString *const FBShowAlertButtonName = @"Create App Alert";
NSString *const FBShowSheetAlertButtonName = @"Create Sheet Alert";
NSString *const FBShowAlertForceTouchButtonName = @"Create Alert (Force Touch)";

@interface FBTvIntegrationTestCase ()
@property (nonatomic, strong) XCUIApplication *testedApplication;
@property (nonatomic, strong) FBSpringboardApplication *springboard;
@end

@implementation FBTvIntegrationTestCase

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
  
  // Force resolving XCUIApplication
  [self.testedApplication query];
  [self.testedApplication resolve];
}

- (void)goToAttributesPage
{
  [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonDown];
  [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonSelect];
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"Button"].fb_isVisible);
}

- (void)goToAlertsPage
{
  [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonSelect];
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[FBShowAlertButtonName].fb_isVisible);
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[FBShowSheetAlertButtonName].fb_isVisible);
}

- (void)goToSpringBoardFirstPage
{
  [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonHome];
  FBAssertWaitTillBecomesTrue([FBSpringboardApplication fb_springboard].icons[@"Settings"].exists);
//  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
//  FBAssertWaitTillBecomesTrue([FBSpringboardApplication fb_springboard].icons[@"Calendar"].fb_isVisible);
}

//- (void)goToSpringBoardExtras
//{
//  [self goToSpringBoardFirstPage];
//  [self.springboard swipeLeft];
//  FBAssertWaitTillBecomesTrue(self.springboard.icons[@"Extras"].fb_isVisible);
//}

//- (void)goToSpringBoardDashboard
//{
//  [self goToSpringBoardFirstPage];
//  [self.springboard swipeRight];
//  NSPredicate *predicate =
//  [NSPredicate predicateWithFormat:
//   @"%K IN %@",
//   FBStringify(XCUIElement, identifier),
//   @[@"SBSearchEtceteraIsolatedView", @"SpotlightSearchField"]
//   ];
//  FBAssertWaitTillBecomesTrue([[self.springboard descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate].fb_isVisible);
//  FBAssertWaitTillBecomesTrue(!self.springboard.icons[@"Calendar"].fb_isVisible);
//}

- (void) selectElement: (XCUIElement*) element {
  
  [[XCUIRemote sharedRemote] pressButton: XCUIRemoteButtonSelect];
}

@end
