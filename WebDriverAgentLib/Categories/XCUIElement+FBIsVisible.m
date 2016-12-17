/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBIsVisible.h"

#import "XCElementSnapshot+FBHelpers.h"
#import "XCTestPrivateSymbols.h"

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  if (!self.lastSnapshot) {
    [self resolve];
  }
  return self.lastSnapshot.fb_isVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

- (BOOL)fb_isVisible
{
  if (CGRectIsEmpty(self.frame) || CGRectIsEmpty(self.visibleFrame)) {
    /*
     It turns out, that XCTest triggers
       Enqueue Failure: UI Testing Failure - Failure fetching attributes for element
       <XCAccessibilityElement: 0x60000025f9e0> Device element: Error Domain=XCTestManagerErrorDomain Code=13
       "Error copying attributes -25202" UserInfo={NSLocalizedDescription=Error copying attributes -25202} <unknown> 0 1
     error in the log if we try to get visibility attribute for an element snapshot, which does not intersect with visible appication area
     or if it has zero width/height. Also, XCTest waits for 15 seconds after this line appears in the log, which makes /source command
     execution extremely slow for some applications.
     */
    return NO;
  }
  return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
}

@end
