/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTap.h"

#import "XCUIElement+Utilities.h"
#import "XCElementSnapshot-Hitpoint.h"
#import "XCEventGenerator+SyncEvents.h"

@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  [self fb_waitUntilFrameIsStable];
  return [[XCEventGenerator sharedGenerator] fb_syncTapAtPoint:self.lastSnapshot.hitPoint orientation:self.interfaceOrientation error:error];
}

@end
