/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBNavigationCommands.h"

#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBResponsePayload.h"
#import "FBXCTSession.h"

#import "XCUIDevice.h"
#import "XCUIApplication.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

@implementation FBNavigationCommands : NSObject

+ (NSArray *)routes
{
    return
    @[
      [[FBRoute POST:@"/session/:sessionID/back"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
          FBXCTSession *session = (FBXCTSession *)request.session;
          XCUIApplication *application = session.application;
          XCUIElement *backButton = application.navigationBars.buttons[@"Back"];
          [backButton tap];
          return FBResponseDictionaryWithOK();
      }]
    ];
}

@end
