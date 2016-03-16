/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTap.h"

#import "XCElementSnapshot-Hitpoint.h"
#import "XCEventGenerator+SyncEvents.h"
#import "XCUIElement+WebDriverAttributes.h"

static const NSUInteger FBMaxQuiescenceTries = 50; // Translates to 5 sec

@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  [self waitForElementQuiescence];
  return [[XCEventGenerator sharedGenerator] fb_syncTapAtPoint:self.lastSnapshot.hitPoint orientation:self.interfaceOrientation error:error];
}

- (void)waitForElementQuiescence
{
  CGRect frame;
  NSUInteger count = 0;
  do {
    if (count > FBMaxQuiescenceTries) {
      return;
    }
    frame = self.wdFrame;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [self resolve];
    count++;
  } while (!CGRectEqualToRect(frame, self.wdFrame));
}

@end
