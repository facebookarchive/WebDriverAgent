/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTap.h"

#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "XCUIElement+Utilities.h"
#import "XCElementSnapshot-Hitpoint.h"
#import "XCEventGenerator.h"
#import "XCSynthesizedEventRecord.h"

@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  [self fb_waitUntilFrameIsStable];
  __block BOOL didSucceed;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)()){
    [[XCEventGenerator sharedGenerator] tapAtPoint:self.lastSnapshot.hitPoint orientation:self.interfaceOrientation handler:^(XCSynthesizedEventRecord *record, NSError *commandError) {
      if (commandError) {
        [FBLogger logFmt:@"Failed to perform tap: %@", commandError];
      }
      if (error) {
        *error = commandError;
      }
      didSucceed = (commandError == nil);
      completion();
    }];
  }];
  return didSucceed;
}

@end
