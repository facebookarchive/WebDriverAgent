/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAlertViewCommands.h"

#import "FBFindElementCommands.h"
#import "FBRouteRequest.h"
#import "FBXCTSession.h"

#import "XCElementSnapshot.h"
#import "XCUIApplication.h"
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
    [[FBRoute GET:@"/session/:sessionID/alert_text"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTSession *session = (FBXCTSession *)request.session;
      NSString *alertText = [self.class currentAlertTextWithApplication:session.application];
      if (!alertText) {
        return FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert");
      }
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, alertText);
    }],
    [[FBRoute POST:@"/session/:sessionID/accept_alert"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTSession *session = (FBXCTSession *)request.session;
      if (![self.class acceptAlertWithApplication:session.application]) {
        return FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert");
      }
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/dismiss_alert"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTSession *session = (FBXCTSession *)request.session;
      if (![self.class dismissAlertWithApplication:session.application]) {
        return FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert");
      }
      return FBResponseDictionaryWithOK();
    }],
  ];
}

+ (void)ensureElementIsNotObstructedByAlertView:(XCUIElement *)element
{
  [self ensureElementIsNotObstructedByAlertView:element alert:[self currentAlertWithApplication:element.application]];
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
  XCUIElement *alert = [self currentAlertWithApplication:element.application];

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

+ (void)throwRequestedItemObstructedByAlertException
{
  @throw [NSException exceptionWithName:FBUAlertObstructingElementException reason:@"Requested element is obstructed by alert or action sheet" userInfo:@{}];
}


#pragma mark - Helpers

+ (id)currentAlertTextWithApplication:(XCUIApplication *)application
{
  XCUIElement *alert = [self currentAlertWithApplication:application];
  if (!alert.exists) {
    return nil;
  }
  NSArray<XCUIElement *> *texts = [alert.staticTexts allElementsBoundByIndex];
  NSString *text = [texts.lastObject wdLabel];
  if (!text) {
    return [NSNull null];
  }
  return text;
}

+ (BOOL)acceptAlertWithApplication:(XCUIApplication *)application
{
  XCUIElement *defaultButton;
  XCUIElement *currentAlert = [self currentAlertWithApplication:application];
  if (currentAlert.elementType == XCUIElementTypeAlert) {
    defaultButton = [[currentAlert.buttons allElementsBoundByIndex] lastObject];
  } else {
    defaultButton = [[currentAlert.buttons allElementsBoundByIndex] firstObject];
  }
  if (!defaultButton) {
    return NO;
  }
  [defaultButton wdActivate];
  return YES;
}

+ (BOOL)dismissAlertWithApplication:(XCUIApplication *)application
{
  XCUIElement *cancelButton;
  XCUIElement *currentAlert = [self currentAlertWithApplication:application];
  if (currentAlert.elementType == XCUIElementTypeAlert) {
    cancelButton = [[currentAlert.buttons allElementsBoundByIndex] firstObject];
  } else {
    cancelButton = [[currentAlert.buttons allElementsBoundByIndex] lastObject];
  }
  if (!cancelButton) {
    return NO;
  }
  [cancelButton wdActivate];
  return YES;
}

+ (XCUIElement *)currentAlertWithApplication:(XCUIApplication *)application
{
  XCUIElement *alert = application.alerts.element;
  if (!alert.exists) {
    alert = application.sheets.element;
  }
  return alert;
}

@end
