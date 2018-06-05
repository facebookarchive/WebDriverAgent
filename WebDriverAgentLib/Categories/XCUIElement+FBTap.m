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
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "XCUIElement+FBUtilities.h"
#import "XCEventGenerator.h"
#import "XCSynthesizedEventRecord.h"
#import "XCElementSnapshot+FBHitPoint.h"
#import "XCPointerEventPath.h"
#import "XCTRunnerDaemonSession.h"

const CGFloat FBTapDuration = 0.01f;

@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  FBElementHitPoint *hitpoint = [self.fb_lastSnapshot fb_hitPointWithAlternativeOnFailure:error];
  if (!hitpoint) {
    return NO;
  }
  return [self fb_performTapAtPoint:hitpoint.point error:error];
}

- (BOOL)fb_tapCoordinate:(CGPoint)relativeCoordinate error:(NSError **)error
{
  CGPoint hitPoint = CGPointMake(self.frame.origin.x + relativeCoordinate.x, self.frame.origin.y + relativeCoordinate.y);
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    /*
     Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
     even if the device is not in portait mode. That is why we need to recalculate them manually
     based on the current orientation value
     */
    hitPoint = FBInvertPointForApplication(hitPoint, self.application.frame.size, self.application.interfaceOrientation);
  }
  return [self fb_performTapAtPoint:hitPoint error:error];
}

- (BOOL)fb_performTapAtPoint:(CGPoint)hitPoint error:(NSError *__autoreleasing*)error
{
  [self fb_waitUntilFrameIsStable];
  __block BOOL didSucceed;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
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

    XCSynthesizedEventRecord *event = [self fb_generateTapEvent:hitPoint orientation:self.interfaceOrientation];
    [[XCTRunnerDaemonSession sharedSession] synthesizeEvent:event completion:^(NSError *invokeError){
      handlerBlock(event, invokeError);
    }];
  }];
  return didSucceed;
}

- (XCSynthesizedEventRecord *)fb_generateTapEvent:(CGPoint)hitPoint orientation:(UIInterfaceOrientation)orientation
{
  XCPointerEventPath *eventPath = [[XCPointerEventPath alloc] initForTouchAtPoint:hitPoint offset:0.0];
  [eventPath liftUpAtOffset:FBTapDuration];
  if (![XCTRunnerDaemonSession sharedSession].useLegacyEventCoordinateTransformationPath) {
    orientation = UIInterfaceOrientationPortrait;
  }
  XCSynthesizedEventRecord *event =
  [[XCSynthesizedEventRecord alloc]
   initWithName:[NSString stringWithFormat:@"Tap on %@", NSStringFromCGPoint(hitPoint)]
   interfaceOrientation:orientation];
  [event addPointerEventPath:eventPath];
  return event;
}

@end
