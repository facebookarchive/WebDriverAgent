/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBClass.h"

@implementation XCUIElement (FBClass)

- (NSString*)fb_class
{
  if (!self.lastSnapshot) {
    [self resolve];
  }
  return [self.lastSnapshot fb_class];
}

@end

@implementation XCElementSnapshot (FBClass)

- (NSString*)fb_class
{
  NSNumber* classId = [NSNumber numberWithInt:5004];
  NSObject* class = [self.additionalAttributes objectForKey:classId];
  if([class isKindOfClass:[NSString class]]){
    return (NSString*)class;
  } else {
    return nil;
  }
}

@end
