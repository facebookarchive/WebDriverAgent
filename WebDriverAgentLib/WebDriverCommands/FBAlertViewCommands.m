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
#import "UIAActionSheet.h"
#import "UIAAlert.h"
#import "UIAButton.h"
#import "UIAElement+ChildHelpers.h"
#import "UIAStaticText.h"

NSString *const FBUAlertObstructingElementException = @"FBUAlertObstructingElementException";

@implementation FBAlertViewCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"GET@/session/:sessionID/alert_text" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSString *alertText = [self.class currentAlertText];
      if (!alertText) {
        NSLog(@"Did not find an alert, returning an error.");
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert"));
        return;
      }
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, alertText));
    },
    @"POST@/session/:sessionID/accept_alert" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      if (![self.class acceptAlert]) {
        NSLog(@"Did not find an alert/default button, returning an error.");
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert"));
        return;
      }
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/dismiss_alert" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      if (![self.class dismissAlert]) {
        NSLog(@"Did not find an alert/cancel button, returning an error.");
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an alert"));
        return;
      }
      completionHandler(FBResponseDictionaryWithOK());
    },
  };
}

+ (void)ensureElementIsNotObstructedByAlertView:(UIAElement *)element
{
  if (![self isElementObstructedByAlertView:element]) {
    return;
  }
  [self throwRequestedItemObstructedByAlertException];
}

+ (BOOL)isElementObstructedByAlertView:(UIAElement *)element
{
  UIAElement *alert = [self _currentAlert];
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
  NSMutableArray *elementBox = [NSMutableArray array];
  for (UIAElement *iElement in elements) {
    if ([FBAlertViewCommands isElementObstructedByAlertView:iElement]) {
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
