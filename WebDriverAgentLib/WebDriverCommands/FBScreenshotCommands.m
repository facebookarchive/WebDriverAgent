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

typedef void (^ScreenShotCallback)(NSData *data);

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"GET@/session/:sessionID/screenshot" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [self.class captureScreenShotOnTarget:[UIATarget localTarget] callback:^(NSData *data) {
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [data base64EncodedStringWithOptions:0]));
      }];
    },
  };
}


#pragma mark - Helpers

const NSString *kUIALoggingKeyScreenshotData = @"kUIALoggingKeyScreenshotData";
+ (void)captureScreenShotOnTarget:(UIATarget *)target callback:(ScreenShotCallback)callback
{
  // Store old delgate
  id oldDelegate = [target delegate];
  id newDelegate = [FBAutomationTargetDelegate delegateWithLogCallback:^BOOL(NSDictionary *data) {
    callback(data[kUIALoggingKeyScreenshotData]);
    // Restore old delegate
    [target setDelegate:oldDelegate];
    return YES;
  }];

  [target setDelegate:newDelegate];
  [target captureScreenWithName:@"irrelevant"];
}

@end
