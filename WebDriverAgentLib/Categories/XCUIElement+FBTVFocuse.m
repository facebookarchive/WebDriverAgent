/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTVFocuse.h"

#import <XCTest/XCUIRemote.h>
#import "FBApplication.h"
#import "FBErrorBuilder.h"
#import <FBTVNavigationTracker.h>
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

int const MAX_ITERATIONS_COUNT = 100;

@implementation XCUIElement (FBTVFocuse)

-(BOOL)fb_focuseWithError:(NSError**) error
{
  [[FBApplication fb_activeApplication] fb_waitUntilSnapshotIsStable];
  if (self.wdEnabled) {
    FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:self];
    for (int i = 0; i < MAX_ITERATIONS_COUNT; i++) {
      if (self.hasFocus) {
        return YES;
      }
      if (self.exists) {
        FBTVDirection direction = tracker.directionToMoveFocuse;
        if(direction != FBTVDirectionNone) {
          [[XCUIRemote sharedRemote] pressButton: (XCUIRemoteButton)direction];
          continue;
        }
      }
      [[[FBErrorBuilder builder] withDescription:@"Unable to reach element. Try to use XCUIRemote commands."]
       buildError:error];
      return NO;
    }
  }
  [[[FBErrorBuilder builder] withDescription:@"Element could not be focused."]
   buildError:error];
  return NO;
}

-(BOOL)fb_selectWithError:(NSError**) error
{
  BOOL result = [self fb_focuseWithError: error];
  if (result) {
    [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonSelect];
  }
  return result;
}
@end
