/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCache.h"

#import "FBAlert.h"
#import "XCUIElement.h"
#import "XCUIElement+FBUtilities.h"
#import "XCAccessibilityElement.h"

@interface FBElementCache ()
@property (atomic, strong) NSMutableDictionary *elementCache;
@end

@implementation FBElementCache

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _elementCache = [[NSMutableDictionary alloc] init];
  return self;
}

- (NSString *)storeElement:(XCUIElement *)element
{
  XCElementSnapshot *snapshot = element.fb_lastSnapshot;
  XCAccessibilityElement *axElement = snapshot.accessibilityElement;
  unsigned long long elementId = [axElement elementID];
  int processId = [axElement processIdentifier];
  
  uint8_t b[16] = {0};
  memcpy(b, &elementId, sizeof(long long));
  memcpy(b + sizeof(long long), &processId, sizeof(int));
  
  NSUUID *uuidValue = [[NSUUID alloc] initWithUUIDBytes:b];
  NSString *uuid = [uuidValue UUIDString];
  self.elementCache[uuid] = element;
  return uuid;
}

- (XCUIElement *)elementForUUID:(NSString *)uuid
{
  if (!uuid) {
    return nil;
  }
  XCUIElement *element = self.elementCache[uuid];
  [element resolve];
  return element;
}

@end
