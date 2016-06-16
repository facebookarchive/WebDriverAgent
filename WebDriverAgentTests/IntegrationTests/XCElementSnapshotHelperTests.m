/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "XCElementSnapshot+Helpers.h"
#import "XCUIElement.h"

static NSString *const FBShowAlertButtonName = @"Show alert";

@interface XCElementSnapshotHelperTests : XCTestCase
@property (nonatomic, strong) XCUIApplication *testedApplication;
@end

@implementation XCElementSnapshotHelperTests

- (void)setUp
{
  [super setUp];
  self.testedApplication = [XCUIApplication new];
  [self.testedApplication launch];
}

- (void)testDescendantsMatchingType
{
  XCUIElement *mainView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(mainView.exists);
  [mainView resolve];
  NSArray<XCElementSnapshot *> *matchingSnapshots = [mainView.lastSnapshot fb_descendantsMatchingType:XCUIElementTypeButton];
  XCTAssertTrue(matchingSnapshots.count >= 3);
  XCElementSnapshot *buttonSnapshot = [[matchingSnapshots filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"label = %@", FBShowAlertButtonName]] lastObject];
  XCTAssertEqualObjects(buttonSnapshot.label, FBShowAlertButtonName);
  XCTAssertEqual(buttonSnapshot.elementType, XCUIElementTypeButton);
}

- (void)testParentMatchingType
{
  XCUIElement *button = self.testedApplication.buttons[FBShowAlertButtonName];
  XCTAssertTrue(button.exists);
  [button resolve];
  XCElementSnapshot *windowSnapshot = [button.lastSnapshot fb_parentMatchingType:XCUIElementTypeWindow];
  XCTAssertNotNil(windowSnapshot);
  XCTAssertEqual(windowSnapshot.elementType, XCUIElementTypeWindow);
}

- (void)testMainWindow
{
  [self.testedApplication query];
  [self.testedApplication resolve];
  XCTAssertNotNil(self.testedApplication.lastSnapshot.fb_mainWindow);
  XCTAssertTrue(self.testedApplication.lastSnapshot.fb_mainWindow.isMainWindow);
}

@end
