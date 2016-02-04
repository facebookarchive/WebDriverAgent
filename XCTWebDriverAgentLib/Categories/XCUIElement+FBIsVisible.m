/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBIsVisible.h"

#import "XCElementSnapshot+Helpers.h"

@implementation XCUIElement (FBIsVisible)

- (BOOL)isFBVisible
{
  return self.lastSnapshot.isFBVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)

- (BOOL)isFBVisible
{
  return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
}

@end
