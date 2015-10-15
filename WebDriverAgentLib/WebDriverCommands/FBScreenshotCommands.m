/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreenshotCommands.h"

#import "FBAutomationTargetDelegate.h"
#import "UIATarget.h"

static NSString *const kUIALoggingKeyScreenshotData = @"kUIALoggingKeyScreenshotData";

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/session/:sessionID/screenshot"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSString *screenshot = [[self captureScreenShotOnTarget:UIATarget.localTarget] base64EncodedStringWithOptions:0];
      return [FBResponsePayload okWith:screenshot];
    }]
  ];
}

#pragma mark - Helpers

+ (NSData *)captureScreenShotOnTarget:(UIATarget *)target
{
  __block NSData *screenshotData = nil;

  // Store old delgate
  id oldDelegate = [target delegate];
  id newDelegate = [FBAutomationTargetDelegate delegateWithLogCallback:^ BOOL (NSDictionary *userInfo) {
    screenshotData = userInfo[kUIALoggingKeyScreenshotData];
    // Restore old delegate
    [target setDelegate:oldDelegate];
    return YES;
  }];

  [target setDelegate:newDelegate];
  [target captureScreenWithName:@"irrelevant"];
  return screenshotData;
}
@end
