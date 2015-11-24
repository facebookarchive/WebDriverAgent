// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTWebDriverAgentLib/XCElementSnapshot.h>

@interface XCElementSnapshot (Helpers)

+ (XCElementSnapshot *)fb_snapshotForAccessibilityElement:(XCAccessibilityElement *)accessibilityElement;

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type;

@end
