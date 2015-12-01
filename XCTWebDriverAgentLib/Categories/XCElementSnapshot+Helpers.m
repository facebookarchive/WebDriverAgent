/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCElementSnapshot+Helpers.h"

#import "FBWDALogger.h"
#import "XCAXClient_iOS.h"
#import "XCTestDriver.h"

@implementation XCElementSnapshot (Helpers)

+ (XCElementSnapshot *)fb_snapshotForAccessibilityElement:(XCAccessibilityElement *)accessibilityElement
{
  __block BOOL loading = YES;
  __block XCElementSnapshot *snapshot;
  [[XCTestDriver sharedTestDriver].managerProxy _XCT_snapshotForElement:accessibilityElement
                                                             attributes:[[XCAXClient_iOS sharedClient] defaultAttributes]
                                                             parameters: [[XCAXClient_iOS sharedClient] defaultParameters]
                                                                  reply:^(XCElementSnapshot *iSnapshot, NSError *error) {
                                                                    if (error) {
                                                                      [FBWDALogger logFmt:@"Error: %@", error];
                                                                    }
                                                                    snapshot = iSnapshot;
                                                                    loading = NO;
                                                                  }];
  while (loading) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  return snapshot;
}

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type
{
  return [self descendantsByFilteringWithBlock:^BOOL(XCElementSnapshot *snapshot){
    return snapshot.elementType == type;
  }];
}

- (XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type
{
  XCElementSnapshot *snapshot = self.parent;
  while (snapshot && snapshot.elementType != type) {
    snapshot = snapshot.parent;
  }
  return snapshot;
}

@end
