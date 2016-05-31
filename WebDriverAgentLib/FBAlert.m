/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAlert.h"

#import <XCTest/XCUICoordinate.h>

#import "FBApplication.h"
#import "FBErrorBuilder.h"
#import "FBFindElementCommands.h"
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

NSString *const FBAlertObstructingElementException = @"FBAlertObstructingElementException";

@interface XCUIApplication (FBAlert)

- (XCUIElement *)fb_alertElement;

@end

@implementation XCUIApplication (FBAlert)

- (XCUIElement *)fb_alertElement
{
  XCUIElement *alert = self.alerts.element;
  if (alert.exists) {
    return alert;
  }
  alert = self.sheets.element;
  if (alert.exists) {
    return alert;
  }
  return nil;
}

@end

@interface FBAlert ()
@property (nonatomic, strong) XCUIApplication *application;
@end

@implementation FBAlert

+ (instancetype)alertWithApplication:(XCUIApplication *)application
{
  FBAlert *alert = [FBAlert new];
  alert.application = application;
  return alert;
}

- (BOOL)isPresent
{
  return self.alertElement.exists;
}

- (NSString *)text
{
  NSArray<XCElementSnapshot *> *staticTextList = [self.alertElement.lastSnapshot fb_descendantsMatchingType:XCUIElementTypeStaticText];
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

- (BOOL)acceptWithError:(NSError **)error
{
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByIndex;

  XCUIElement *defaultButton;
  if (alertElement.elementType == XCUIElementTypeAlert) {
    defaultButton = buttons.lastObject;
  } else {
    defaultButton = buttons.firstObject;
  }
  if (!defaultButton) {
    return
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"Failed to find accept button for alert: %@", alertElement]
     buildError:error];
  }
  return [defaultButton fb_tapWithError:error];
}

- (BOOL)dismissWithError:(NSError **)error
{
  XCUIElement *cancelButton;
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByIndex;

  if (alertElement.elementType == XCUIElementTypeAlert) {
    cancelButton = buttons.firstObject;
  } else {
    cancelButton = buttons.lastObject;
  }
  if (!cancelButton) {
    return
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"Failed to find dismiss button for alert: %@", alertElement]
     buildError:error];
    return NO;
  }
  return [cancelButton fb_tapWithError:nil];
}

- (void)checkIfObstructsElement:(XCUIElement *)element
{
  XCUIElement *alert = self.alertElement;
  if (![self.class isElementObstructedByAlertView:element alert:alert]) {
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

- (NSArray<XCUIElement *> *)filterObstructedElements:(NSArray<XCUIElement *> *)elements
{
  XCUIElement *element = elements.lastObject;
  if (!element) {
    return elements;
  }
  NSMutableArray *elementBox = [NSMutableArray array];
  for (XCUIElement *iElement in elements) {
    if ([FBAlert isElementObstructedByAlertView:iElement alert:self.alertElement]) {
      continue;
    }
    [elementBox addObject:iElement];
  }
  if (elementBox.count == 0 && elements.count != 0) {
    [self throwRequestedItemObstructedByAlertException];
  }
  return elementBox.copy;
}

- (XCUIElement *)alertElement
{
  XCUIElement *alert = self.application.fb_alertElement ?: [FBSpringboardApplication fb_springboard].fb_alertElement;
  if (!alert.exists) {
    return nil;
  }
  [alert resolve];
  return alert;
}

- (void)throwRequestedItemObstructedByAlertException __attribute__((noreturn))
{
  @throw [NSException exceptionWithName:FBAlertObstructingElementException reason:@"Requested element is obstructed by alert or action sheet" userInfo:@{}];
}

@end
