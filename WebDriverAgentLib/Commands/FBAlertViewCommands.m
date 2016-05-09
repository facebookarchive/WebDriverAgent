/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAlertViewCommands.h"

#import <XCTest/XCUICoordinate.h>

#import "FBApplication.h"
#import "FBFindElementCommands.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBSpringboardApplication.h"
#import "FBWDALogger.h"
#import "XCAXClient_iOS.h"
#import "XCElementSnapshot+Helpers.h"
#import "XCElementSnapshot-Hitpoint.h"
#import "XCElementSnapshot.h"
#import "XCEventGenerator+SyncEvents.h"
#import "XCTestManager_ManagerInterface-Protocol.h"
#import "XCUICoordinate.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

NSString *const FBUAlertObstructingElementException = @"FBUAlertObstructingElementException";

@implementation FBAlertViewCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/alert_text"] respondWithTarget:self action:@selector(handleAlertTextCommand:)],
    [[FBRoute POST:@"/accept_alert"] respondWithTarget:self action:@selector(handleAlertAcceptCommand:)],
    [[FBRoute POST:@"/dismiss_alert"] respondWithTarget:self action:@selector(handleAlertDismissCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleAlertTextCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSString *alertText = [self.class currentAlertTextWithApplication:session.application];
  if (!alertText) {
    return FBResponseWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert");
  }
  return FBResponseWithStatus(FBCommandStatusNoError, alertText);
}

+ (id<FBResponsePayload>)handleAlertAcceptCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  if (![self.class acceptAlertWithApplication:session.application]) {
    return FBResponseWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert");
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleAlertDismissCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  if (![self.class dismissAlertWithApplication:session.application]) {
    return FBResponseWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert");
  }
  return FBResponseWithOK();
}


#pragma mark - Helpers

+ (void)ensureElementIsNotObstructedByAlertView:(XCUIElement *)element
{
  [self ensureElementIsNotObstructedByAlertView:element alert:[self applicationAlertWithApplication:(FBApplication *)element.application]];
}

+ (void)ensureElementIsNotObstructedByAlertView:(XCUIElement *)element alert:(XCUIElement *)alert
{
  if (![self isElementObstructedByAlertView:element alert:alert]) {
    return;
  }
  [self throwRequestedItemObstructedByAlertException];
}

+ (BOOL)isElementObstructedByAlertView:(XCUIElement *)element alert:(XCUIElement *)alert
{
  if (!alert.exists) {
    return NO;
  }
  [alert resolve];
  [element resolve];
  if ([alert.lastSnapshot _isAncestorOfElement:element.lastSnapshot]) {
    return NO;
  }
  if ([alert.lastSnapshot _matchesElement:element.lastSnapshot]) {
    return NO;
  }
  return YES;
}

+ (NSArray *)filterElementsObstructedByAlertView:(NSArray *)elements
{
  XCUIElement *element = elements.lastObject;
  if (!element) {
    return elements;
  }
  XCUIElement *alert = [self applicationAlertWithApplication:(FBApplication *)element.application];

  NSMutableArray *elementBox = [NSMutableArray array];
  for (XCUIElement *iElement in elements) {
    if ([FBAlertViewCommands isElementObstructedByAlertView:iElement alert:alert]) {
      continue;
    }
    [elementBox addObject:iElement];
  }
  if (elementBox.count == 0 && elements.count != 0) {
    [self throwRequestedItemObstructedByAlertException];
  }
  return elementBox.copy;
}

+ (void)throwRequestedItemObstructedByAlertException __attribute__((noreturn))
{
  @throw [NSException exceptionWithName:FBUAlertObstructingElementException reason:@"Requested element is obstructed by alert or action sheet" userInfo:@{}];
}


#pragma mark - Helpers

+ (id)currentAlertTextWithApplication:(FBApplication *)application
{
  XCUIElement *alertSnapshot = [self alertSnapshotWithApplication:application];
  if (!alertSnapshot) {
    return nil;
  }
  NSArray<XCElementSnapshot *> *staticTextList = [alertSnapshot.lastSnapshot fb_descendantsMatchingType:XCUIElementTypeStaticText];
  NSMutableString *mText = [NSMutableString string];
  for (XCElementSnapshot *staticText in staticTextList) {
    if (staticText.wdLabel && staticText.isWDVisible) {
      [mText appendFormat:@"%@\n", staticText.wdLabel];
    }
  }
  // Removing last '\n'
  if (mText.length > 0) {
    [mText replaceCharactersInRange:NSMakeRange(mText.length - @"\n".length, @"\n".length) withString:@""];
  }
  return mText.length > 0 ? mText.copy : [NSNull null];
}

+ (BOOL)acceptAlertWithApplication:(FBApplication *)application
{
  XCUIElement *alert = [self alertSnapshotWithApplication:application];
  NSArray<XCUIElement *> *buttons = [alert descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByIndex;

  XCUIElement *defaultButton;
  if (alert.elementType == XCUIElementTypeAlert) {
    defaultButton = buttons.lastObject;
  } else {
    defaultButton = buttons.firstObject;
  }
  if (!defaultButton) {
    [FBWDALogger logFmt:@"Failed to find accept button for alert: %@", alert];
    return NO;
  }
  return [defaultButton fb_tapWithError:nil];
}

+ (BOOL)dismissAlertWithApplication:(FBApplication *)application
{
  XCUIElement *cancelButton;
  XCUIElement *alert = [self alertSnapshotWithApplication:application];
  NSArray<XCUIElement *> *buttons = [alert descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByIndex;

  if (alert.elementType == XCUIElementTypeAlert) {
    cancelButton = buttons.firstObject;
  } else {
    cancelButton = buttons.lastObject;
  }
  if (!cancelButton) {
    [FBWDALogger logFmt:@"Failed to find dismiss button for alert: %@", alert];
    return NO;
  }
  return [cancelButton fb_tapWithError:nil];
}

+ (XCUIElement *)applicationAlertWithApplication:(FBApplication *)application
{
  XCUIElement *alert = application.alerts.element;
  if (!alert.exists) {
    alert = application.sheets.element;
  }
  return alert;
}

+ (XCUIElement *)alertSnapshotWithApplication:(FBApplication *)application
{
  XCUIElement *alert = [self applicationAlertWithApplication:application];
  if (!alert.exists) {
    alert = [self applicationAlertWithApplication:[FBSpringboardApplication fb_springboard]];
  }
  if (alert.exists) {
    [alert resolve];
    return alert;
  }
  return nil;
}

@end
