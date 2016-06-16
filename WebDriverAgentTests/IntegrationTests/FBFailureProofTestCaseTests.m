/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBFailureProofTestCase.h"
#import "FBExceptionHandler.h"

static BOOL FBTestPreventElementSearchFailureDidFinishExecution;
static BOOL FBTestAppDeadLockDetectionDidFinishExecution;

@interface FBFailureProofTestCaseTests : FBFailureProofTestCase
@property (nonatomic, strong) XCUIApplication *application;
@end

@implementation FBFailureProofTestCaseTests

- (void)setUp
{
  [super setUp];
  self.application = [XCUIApplication new];
  [self.application launch];
}

- (void)testPreventElementSearchFailure
{
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  [self.application.buttons[@"kaboom"] tap];
  XCTAssertFalse(self.shouldHaltWhenReceivesControl);
  FBTestPreventElementSearchFailureDidFinishExecution = YES;
}

- (void)testAppDeadLockDetection
{
  XCTAssertThrowsSpecificNamed({
    [self.application.buttons[@"Deadlock app"] tap];
    [self.application.buttons[@"kaboom"] tap];
  }, NSException, FBApplicationDeadlockDetectedException);
  XCTAssertFalse(self.shouldHaltWhenReceivesControl);
  FBTestAppDeadLockDetectionDidFinishExecution = YES;
}

- (void)testPreventAssertFailure
{
  XCTAssertNotNil(nil);
}

#pragma mark - Tests confirming full test execution of other tests

/**
 A 'bit' hacky, but the only way to confirm that e.g. 'testPreventElementSearchFailure' has fully executed.
 To do that we:
 1) Create static variable
 2) Change this variable at the and of test's execution
 3) Confirm in NEXT test that variable has changed
 Tricky part is the third step. As you care about test execution order, which you NEVER should care about.
 However knowing that tests are executed alphabetically, it can be hacked by adding '_' to execution confirming test's name.
 They might start failing if tests are executed in different order.
 */
- (void)testPreventElementSearchFailure_ // Confirms that testPreventElementSearchFailure has been fully executed
{
  XCTAssertTrue(FBTestPreventElementSearchFailureDidFinishExecution);
}

- (void)testAppDeadLockDetection_ // Confirms that testAppDeadLockDetection has been fully executed
{
  XCTAssertTrue(FBTestAppDeadLockDetectionDidFinishExecution);
}

@end
