/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAlertViewCommands.h"

#import "FBAlert.h"
#import "FBApplication.h"
#import "FBRouteRequest.h"
#import "FBSession.h"

@implementation FBAlertViewCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/alert/text"] respondWithTarget:self action:@selector(handleAlertGetTextCommand:)],
    [[FBRoute GET:@"/alert/text"].withoutSession respondWithTarget:self action:@selector(handleAlertGetTextCommand:)],
    [[FBRoute POST:@"/alert/text"] respondWithTarget:self action:@selector(handleAlertSetTextCommand:)],
    [[FBRoute POST:@"/alert/accept"] respondWithTarget:self action:@selector(handleAlertAcceptCommand:)],
    [[FBRoute POST:@"/alert/accept"].withoutSession respondWithTarget:self action:@selector(handleAlertAcceptCommand:)],
    [[FBRoute POST:@"/alert/dismiss"] respondWithTarget:self action:@selector(handleAlertDismissCommand:)],
    [[FBRoute POST:@"/alert/dismiss"].withoutSession respondWithTarget:self action:@selector(handleAlertDismissCommand:)],
    [[FBRoute GET:@"/wda/alert/buttons"] respondWithTarget:self action:@selector(handleGetAlertButtonsCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleAlertGetTextCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSString *alertText = [FBAlert alertWithApplication:session.activeApplication].text;
  if (!alertText) {
    return FBResponseWithStatus(FBCommandStatusNoAlertPresent, nil);
  }
  return FBResponseWithStatus(FBCommandStatusNoError, alertText);
}

+ (id<FBResponsePayload>)handleAlertSetTextCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  id value = request.arguments[@"value"];
  if (!value) {
    return FBResponseWithErrorFormat(@"Missing 'value' parameter");
  }
  FBAlert *alert = [FBAlert alertWithApplication:session.activeApplication];
  if (!alert.isPresent) {
    return FBResponseWithStatus(FBCommandStatusNoAlertPresent, nil);
  }
  NSString *textToType = value;
  if ([value isKindOfClass:[NSArray class]]) {
    textToType = [value componentsJoinedByString:@""];
  }
  NSError *error;
  if (![alert typeText:textToType error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleAlertAcceptCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSString *name = request.arguments[@"name"];
  FBAlert *alert = [FBAlert alertWithApplication:session.activeApplication];
  NSError *error;

  if (!alert.isPresent) {
    return FBResponseWithStatus(FBCommandStatusNoAlertPresent, nil);
  }
  if (name) {
    if (![alert clickAlertButton:name error:&error]) {
      return FBResponseWithError(error);
    }
  } else if (![alert acceptWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleAlertDismissCommand:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSString *name = request.arguments[@"name"];
  FBAlert *alert = [FBAlert alertWithApplication:session.activeApplication];
  NSError *error;
    
  if (!alert.isPresent) {
    return FBResponseWithStatus(FBCommandStatusNoAlertPresent, nil);
  }
  if (name) {
    if (![alert clickAlertButton:name error:&error]) {
      return FBResponseWithError(error);
    }
  } else if (![alert dismissWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetAlertButtonsCommand:(FBRouteRequest *)request {
  FBSession *session = request.session;
  FBAlert *alert = [FBAlert alertWithApplication:session.activeApplication];

  if (!alert.isPresent) {
    return FBResponseWithStatus(FBCommandStatusNoAlertPresent, nil);
  }
  NSArray *labels = alert.buttonLabels;
  return FBResponseWithStatus(FBCommandStatusNoError, labels);
}
@end
