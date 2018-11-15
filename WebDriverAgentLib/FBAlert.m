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
#import "FBHomeboardApplication.h"
#import "FBLogger.h"
#import "FBXCodeCompatibility.h"
#import "XCAXClient_iOS.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCElementSnapshot.h"
#import "XCTestManager_ManagerInterface-Protocol.h"
#import "XCUICoordinate.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "XCUIApplication+FBFocused.h"
#import "XCUIElement+FBTVFocuse.h"

NSString *const FBAlertObstructingElementException = @"FBAlertObstructingElementException";
NSString *const FBAlertWindowIdentifier = @"dialogWindow";

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

#if TARGET_OS_TV

  alert = self.windows[FBAlertWindowIdentifier];
  if (alert.exists) {
    return alert;
  }
  
#endif
  
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
  NSArray<XCUIElement *> *staticTextList = [alert descendantsMatchingType:XCUIElementTypeStaticText].allElementsBoundByIndex;
  NSMutableArray<NSString *> *resultText = [NSMutableArray array];
  for (XCUIElement *staticText in staticTextList) {
    if (staticText.wdLabel && staticText.isWDVisible) {
      [resultText addObject:[NSString stringWithFormat:@"%@", staticText.wdLabel]];
    }
  }
#if TARGET_OS_TV
  // System alerts has description text in the text views
  NSArray<XCUIElement *> *textList = [alert descendantsMatchingType:XCUIElementTypeTextView].allElementsBoundByIndex;
  for (XCUIElement *textView in textList) {
    if (textView.wdValue && textView.isWDVisible) {
      [resultText addObject:[NSString stringWithFormat:@"%@", textView.wdValue]];
    }
  }
  
  // Application and sheet alerts have text in the other elements, not in the the static text
  if (!resultText.count) {
    NSArray<XCUIElement *> *otherElements = [alert descendantsMatchingType:XCUIElementTypeOther].allElementsBoundByIndex;
    for (XCUIElement *otherElement in otherElements) {
      // element should be visible, with text and no children
      if (otherElement.wdLabel && otherElement.isWDVisible && ![otherElement descendantsMatchingType:XCUIElementTypeAny].count) {
        [resultText addObject:[NSString stringWithFormat:@"%@", otherElement.wdLabel]];
      }
    }
  }
#endif
  
  if (resultText.count) {
    return [resultText componentsJoinedByString:@"\n"];
  }
  // return null to reflect the fact there is an alert, but it does not contain any text
  return (id)[NSNull null];
}

- (NSArray *)buttonLabels
{
  NSMutableArray *value = [NSMutableArray array];
  XCUIElement *alertElement = self.alertElement;
  if (!alertElement) {
    return nil;
  }
  NSArray<XCUIElement *> *buttons = [self alertButtons];
  for(XCUIElement *button in buttons) {
    [value addObject:[button wdLabel]];
  }
  return value;
}

- (BOOL)acceptWithError:(NSError **)error
{
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [self alertButtons];

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
  return [self submitAlertButton:defaultButton withError:error];
}

- (BOOL)dismissWithError:(NSError **)error
{
  XCUIElement *cancelButton;
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [self alertButtons];

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
  return [self submitAlertButton:cancelButton withError:error];
}

- (BOOL)clickAlertButton:(NSString *)label error:(NSError **)error
{
  
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [self alertButtons];
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
  return [self submitAlertButton:requestedButton withError:error];
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

- (NSArray<XCUIElement *> *)alertButtons
{
  XCUIElement *alertElement = self.alertElement;
  NSArray<XCUIElement *> *buttons = [alertElement descendantsMatchingType:XCUIElementTypeButton].allElementsBoundByIndex;
#if TARGET_OS_IOS
  return buttons;
#elif TARGET_OS_TV
  if ([self isAnyFocused:buttons]) {
    return buttons;
  }
  
  // Focusable button elements on some alerts has type XCUIElementTypeOther
  NSMutableArray<NSString *> *buttonsName = [NSMutableArray array];
  [buttons enumerateObjectsUsingBlock:^(XCUIElement *element, NSUInteger idx, BOOL *stop) {
    NSString *name = element.wdName;
    [buttonsName addObject:name];
  }];
  
  NSMutableArray<XCUIElement *> *buttonsAlt = [NSMutableArray array];
  [buttonsName enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == 'XCUIElementTypeOther' AND name == %@", name];
    NSArray<XCUIElement *> *matchedElements = [alertElement fb_descendantsMatchingPredicate:predicate shouldReturnAfterFirstMatch:YES];
    [buttonsAlt addObjectsFromArray:matchedElements];
  }];
  if (![self isAnyFocused:buttonsAlt]) {
    NSLog(@"FAIL");
  }
  return buttonsAlt;
#endif
}

- (XCUIElement *)alertElement
{
  XCUIElement *alert = self.application.fb_alertElement ?: [FBApplication fb_activeApplication].fb_alertElement;
  if (!alert.exists) {
    return nil;
  }
  [alert resolve];
  return alert;
}

- (BOOL) submitAlertButton: (XCUIElement *) button withError:(NSError **) error
{
#if TARGET_OS_IOS
  return [button fb_tapWithError:error];
#elif TARGET_OS_TV
  return [button fb_selectWithError:error];
#endif
}

#pragma mark - Utilities

#if TARGET_OS_TV

- (BOOL) isAnyFocused:(NSArray<XCUIElement *> *) elements {
  for(XCUIElement *element in elements) {
    if(element.hasFocus == YES) {
      return YES;
    }
  }
  return NO;
}

#endif

@end
