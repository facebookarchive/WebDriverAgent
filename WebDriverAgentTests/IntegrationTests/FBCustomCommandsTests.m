/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBIntegrationTestCase.h"
#import "FBCustomCommands.h"
#import "XCUIElement.h"
#import "XCUIElement+FBFind.h"
#import "XCUIApplication+FBHelpers.h"

@interface FBCustomCommandsTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *testedView;
@end

@implementation FBCustomCommandsTests

- (void)setUp
{
  [super setUp];
}

- (void)testWaitForNoAnimations
{
  // XCTest has hardcoded 15 seconds sleep if any failure happens during attribute reading
  NSTimeInterval timeout = 15.0;
  [self goToAttributesPage];
  NSDate *timeStarted = [NSDate date];
  [self.testedApplication waitUntilNoAnimationsActive:timeout];
  NSDictionary *tree = self.testedApplication.fb_tree;
  NSDate *timeFinished = [NSDate date];
  NSTimeInterval executionTime = [timeFinished timeIntervalSinceDate:timeStarted];
  XCTAssertTrue(executionTime < timeout);
  NSLog(@"%@", tree);
}

@end
