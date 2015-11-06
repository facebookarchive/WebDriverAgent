//
//  FBUIAExceptionHandler.m
//  WebDriverAgent
//
//  Created by Marek Cirkos on 06/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "FBUIAExceptionHandler.h"

#import "FBAlertViewCommands.h"
#import "FBResponsePayload.h"
#import "RouteResponse.h"

extern NSString *kUIAExceptionBadPoint;
extern NSString *kUIAExceptionInvalidElement;

@implementation FBUIAExceptionHandler

- (void)webServer:(FBWebServer *)webServer handleException:(NSException *)exception forResponse:(RouteResponse *)response
{
  if ([exception.name isEqualToString:FBUAlertObstructingElementException]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusUnexpectedAlertPresent, @"Alert is obstructing view");
    [payload dispatchWithResponse:response];
    return;
  }
  if ([[exception name] isEqualToString:kUIAExceptionInvalidElement]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusInvalidElementState, [exception description]);
    [payload dispatchWithResponse:response];
    return;
  }
  if ([[exception name] isEqualToString:kUIAExceptionBadPoint]) {
    id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, [exception description]);
    [payload dispatchWithResponse:response];
    return;
  }
  id<FBResponsePayload> payload = FBResponseDictionaryWithStatus(FBCommandStatusStaleElementReference, [exception description]);
  [payload dispatchWithResponse:response];
}

@end

