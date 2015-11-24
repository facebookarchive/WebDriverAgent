// Copyright 2004-present Facebook. All Rights Reserved.

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
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
  }
  return snapshot;
}

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type
{
  return [self descendantsByFilteringWithBlock:^BOOL(XCElementSnapshot *snapshot){
    return snapshot.elementType == type;
  }];
}

@end
