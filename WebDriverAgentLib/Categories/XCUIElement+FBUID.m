/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBUID.h"

#import "XCAccessibilityElement.h"
#import "XCUIElement+FBUtilities.h"

@implementation XCUIElement (FBUID)

- (NSUInteger)fb_uid
{
  return self.fb_lastSnapshot.fb_uid;
}

@end

static BOOL FBShouldUsePayloadForUIDExtraction = YES;
static dispatch_once_t oncePayloadToken;
@implementation XCElementSnapshot (FBUID)

- (NSUInteger)fb_uid
{
  dispatch_once(&oncePayloadToken, ^{
    FBShouldUsePayloadForUIDExtraction = [self.accessibilityElement respondsToSelector:@selector(payload)];
  });
  if (FBShouldUsePayloadForUIDExtraction) {
    return [[self.accessibilityElement.payload objectForKey:@"uid.elementID"] intValue];
  }
  return [[self.accessibilityElement valueForKey:@"_elementID"] intValue];
}

@end
