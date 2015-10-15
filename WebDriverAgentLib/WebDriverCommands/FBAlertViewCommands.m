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
#import "FBWDALogger.h"

#import "UIAActionSheet.h"
#import "UIAAlert.h"
#import "UIAButton.h"
#import "UIAElement+ChildHelpers.h"
#import "UIAStaticText.h"

NSString *const FBUAlertObstructingElementException = @"FBUAlertObstructingElementException";

@implementation FBAlertViewCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/alert_text"] respond:^ id<FBResponse> (FBRequest *request) {
      NSString *alertText = [self.class currentAlertText];
      if (!alertText) {
        [FBWDALogger log:@"Did not find an alert, returning an error."];
        return [FBResponse withStatus:FBCommandStatusNoSuchElement object:@"unable to find an alert"];
      }
      return [FBResponse okWith:alertText];
    }],
    [[FBRoute POST:@"/accept_alert"] respond:^ id<FBResponse> (FBRequest *request) {
      if (![self.class acceptAlert]) {
        [FBWDALogger log:@"Did not find an alert/default button, returning an error."];
        return [FBResponse withStatus:FBCommandStatusNoSuchElement object:@"unable to find an alert"];
      }
      return FBResponse.ok;
    }],
    [[FBRoute POST:@"/dismiss_alert"] respond: ^ id<FBResponse> (FBRequest *request) {
      if (![self.class dismissAlert]) {
        [FBWDALogger log:@"Did not find an alert/cancel button, returning an error."];
        return [FBResponse withStatus:FBCommandStatusNoSuchElement object:@"unable to find an alert"];
      }
      return FBResponse.ok;
    }],
  ];
}

+ (void)ensureElementIsNotObstructedByAlertView:(UIAElement *)element
{
  [self ensureElementIsNotObstructedByAlertView:element alert:[self _currentAlert]];
}

+ (void)ensureElementIsNotObstructedByAlertView:(UIAElement *)element alert:(UIAElement *)alert
{
  if (![self isElementObstructedByAlertView:element alert:alert]) {
    return;
  }
  [self throwRequestedItemObstructedByAlertException];
}

+ (BOOL)isElementObstructedByAlertView:(UIAElement *)element alert:(UIAElement *)alert
{
  if (!alert) {
    return NO;
  }
  if ([FBFindElementCommands isElement:element underElement:alert]) {
    return NO;
  }
  if ([element isEqual:alert]) {
    return NO;
  }
  return YES;
}

+ (NSArray *)filterElementsObstructedByAlertView:(NSArray *)elements
{
  UIAElement *alert = [self _currentAlert];

  NSMutableArray *elementBox = [NSMutableArray array];
  for (UIAElement *iElement in elements) {
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

+ (id)currentAlertText
{
  UIAElement *alert = [self _currentAlert];
  if (!alert) {
    return nil;
  }
  NSArray *texts = [[self _currentAlert] childrenOfClassName:UIAClassString(UIAStaticText)];
  id text = [[texts lastObject] name];

  if (!text) {
    return [NSNull null];
  }
  return text;
}

+ (BOOL)acceptAlert
{
  UIAElement *defaultButton;
  UIAElement *currentAlert = [self _currentAlert];
  if ([currentAlert isKindOfClass:[UIAAlert class]]) {
    defaultButton = [[currentAlert buttons] lastObject];
  } else {
    defaultButton = [[currentAlert childrenOfClassName:UIAClassString(UIAButton)] firstObject];
  }
  if (!defaultButton) {
    return NO;
  }

  [defaultButton tap];
  return YES;
}

+ (BOOL)dismissAlert
{
  UIAElement *cancelButton;
  UIAElement *currentAlert = [self _currentAlert];
  if ([currentAlert isKindOfClass:[UIAAlert class]]) {
    cancelButton = [[currentAlert buttons] firstObject];
  } else {
    cancelButton = [[currentAlert childrenOfClassName:UIAClassString(UIAButton)] lastObject];
  }
  if (!cancelButton) {
    return NO;
  }

  [cancelButton tap];
  return YES;
}

+ (UIAElement *)_currentAlert
{
  UIAElement *element = [FBFindElementCommands elementOfClassOnSimulator:UIAClassString(UIAAlert)];
  if (!element) {
    element = [FBFindElementCommands elementOfClassOnSimulator:UIAClassString(UIAActionSheet)];
  }
  return element;
}

@end
