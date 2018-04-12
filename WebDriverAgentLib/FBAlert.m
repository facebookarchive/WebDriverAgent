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
#import "FBLogger.h"
#import "FBXCodeCompatibility.h"
#import "XCAXClient_iOS.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCElementSnapshot.h"
#import "XCTestManager_ManagerInterface-Protocol.h"
#import "XCUICoordinate.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBTyping.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
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
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
      return alert;
    }
    // In case of iPad we want to check if sheet isn't contained by popover.
    // In that case we ignore it.
    NSPredicate *predicateString = [NSPredicate predicateWithFormat:@"identifier == 'PopoverDismissRegion'"];
    XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicateString];
    if (!query.fb_firstMatch) {
      return alert;
    }
  }
  return nil;
}

@end

@interface FBAlert ()
@property (nonatomic, strong) XCUIApplication *application;
@end

@implementation FBAlert

+ (void)throwRequestedItemObstructedByAlertException __attribute__((noreturn))
{
  @throw [NSException exceptionWithName:FBAlertObstructingElementException reason:@"Requested element is obstructed by alert or action sheet" userInfo:@{}];
}

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
  XCUIElement *alert = self.alertElement;
  if (!alert) {
    return nil;
  }
  NSArray<XCUIElement *> *staticTextList = [alert descendantsMatchingType:XCUIElementTypeStaticText].allElementsBoundByAccessibilityElement;
  NSMutableArray<NSString *> *resultText = [NSMutableArray array];
  for (XCUIElement *staticText in staticTextList) {
    if (staticText.isWDVisible) {
      if (staticText.wdLabel) {
        [resultText addObject:[NSString stringWithFormat:@"%@", staticText.wdLabel]];
      } else if (staticText.wdValue) {
        [resultText addObject:[NSString stringWithFormat:@"%@", staticText.wdValue]];
      }
    }
  }
  if (resultText.count) {
    return [resultText componentsJoinedByString:@"\n"];
  }
  // return null to reflect the fact there is an alert, but it does not contain any text
  return (id)[NSNull null];
}

- (BOOL)typeText:(NSString *)text error:(NSError **)error
{
  XCUIElement *alert = self.alertElement;
  NSArray<XCUIElement *> *textFields = alert.textFields.allElementsBoundByAccessibilityElement;
  NSArray<XCUIElement *> *secureTextFiels = alert.secureTextFields.allElementsBoundByAccessibilityElement;
  if (textFields.count + secureTextFiels.count > 1) {
    return [[[FBErrorBuilder builder]
      withDescriptionFormat:@"The alert contains more than one input field"]
     buildError:error];
  }
  if (0 == textFields.count + secureTextFiels.count) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"The alert contains no input fields"]
            buildError:error];
  }
  if (secureTextFiels.count > 0) {
    return [secureTextFiels.firstObject fb_typeText:text error:error];
  }
  return [textFields.firstObject fb_typeText:text error:error];
}

- (NSArray *)buttonLabels
{
  NSMutableArray *value = [NSMutableArray array];
  XCUIElement *alertElement = self.alertElement;
  if (!alertElement) {
    return nil;
  }
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByAccessibilityElement;
  for(XCUIElement *button in buttons) {
    [value addObject:[button wdLabel]];
  }
  return value;
}

- (BOOL)acceptWithError:(NSError **)error
{
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByAccessibilityElement;

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
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByAccessibilityElement;

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
  return [cancelButton fb_tapWithError:error];
}

- (BOOL)clickAlertButton:(NSString *)label error:(NSError **)error {

  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByAccessibilityElement;
  XCUIElement *requestedButton;

  for(XCUIElement *button in buttons) {
    if([[button wdLabel] isEqualToString:label]){
      requestedButton = button;
      break;
    }
  }

  if(!requestedButton) {
    return
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"Failed to find button with label %@ for alert: %@", label, alertElement]
     buildError:error];
  }

  return [requestedButton fb_tapWithError:error];
}

+ (BOOL)isElementObstructedByAlertView:(XCUIElement *)element alert:(XCUIElement *)alert
{
  if (!alert.exists) {
    return NO;
  }
  XCElementSnapshot *alertSnapshot = alert.fb_lastSnapshot;
  XCElementSnapshot *elementSnapshot = element.fb_lastSnapshot;
  if ([alertSnapshot _isAncestorOfElement:elementSnapshot]) {
    return NO;
  }
  if ([alertSnapshot _matchesElement:elementSnapshot]) {
    return NO;
  }
  return YES;
}

- (NSArray<XCUIElement *> *)filterObstructedElements:(NSArray<XCUIElement *> *)elements
{
  XCUIElement *alertElement = self.alertElement;
  XCUIElement *element = elements.lastObject;
  if (!element) {
    return elements;
  }
  NSMutableArray *elementBox = [NSMutableArray array];
  for (XCUIElement *iElement in elements) {
    if ([FBAlert isElementObstructedByAlertView:iElement alert:alertElement]) {
      continue;
    }
    [elementBox addObject:iElement];
  }
  if (elementBox.count == 0 && elements.count != 0) {
    [FBAlert throwRequestedItemObstructedByAlertException];
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

@end
