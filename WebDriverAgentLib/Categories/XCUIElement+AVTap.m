/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+AVTap.h"

#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "XCUIElement+FBUtilities.h"
#import "XCElementSnapshot-Hitpoint.h"
#import "XCEventGenerator.h"
#import "XCSynthesizedEventRecord.h"

@implementation XCUIElement (AVTap)

- (BOOL)av_tapForClearWithError:(NSError **)error
{
  [self fb_waitUntilFrameIsStable];
  __block BOOL didSucceed;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)()){
    CGPoint hitPoint = [self coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)].screenPoint;
    XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
      if (commandError) {
        [FBLogger logFmt:@"Failed to perform tap: %@", commandError];
      }
      if (error) {
        *error = commandError;
      }
      didSucceed = (commandError == nil);
      completion();
    };
    XCEventGenerator *eventGenerator = [XCEventGenerator sharedGenerator];
    if ([eventGenerator respondsToSelector:@selector(tapAtTouchLocations:numberOfTaps:orientation:handler:)]) {
      [eventGenerator tapAtTouchLocations:@[[NSValue valueWithCGPoint:hitPoint]] numberOfTaps:1 orientation:self.interfaceOrientation handler:handlerBlock];
    }
    else {
      [eventGenerator tapAtPoint:hitPoint orientation:self.interfaceOrientation handler:handlerBlock];
    }
  }];
  return didSucceed;
}

@end
