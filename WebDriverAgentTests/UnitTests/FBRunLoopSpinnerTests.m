/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBRunLoopSpinner.h"

@interface FBRunLoopSpinnerTests : XCTestCase
@property (nonatomic, strong) FBRunLoopSpinner *spinner;
@end

/**
 Non of the test methods should block testing thread.
 If they do, that means they are broken
 */
@implementation FBRunLoopSpinnerTests

- (void)setUp
{
  [super setUp];
  self.spinner = [[FBRunLoopSpinner new] timeout:0.1];
}

- (void)testSpinUntilCompletion
{
  __block BOOL _didExecuteBlock = NO;
  [FBRunLoopSpinner spinUntilCompletion:^(void (^completion)(void)) {
    _didExecuteBlock = YES;
    completion();
  }];
  XCTAssertTrue(_didExecuteBlock);
}

- (void)testSpinUntilTrue
{
  __block BOOL _didExecuteBlock = NO;
  BOOL didSucceed =
  [self.spinner spinUntilTrue:^BOOL{
    _didExecuteBlock = YES;
    return YES;
  }];
  XCTAssertTrue(didSucceed);
  XCTAssertTrue(_didExecuteBlock);
}

- (void)testSpinUntilTrueTimeout
{
  NSError *error;
  BOOL didSucceed =
  [self.spinner spinUntilTrue:^BOOL{
    return NO;
  } error:&error];
  XCTAssertFalse(didSucceed);
  XCTAssertNotNil(error);
}

- (void)testSpinUntilTrueTimeoutMessage
{
  NSString *expectedMessage = @"Magic message";
  NSError *error;
  BOOL didSucceed =
  [[self.spinner timeoutErrorMessage:expectedMessage]
   spinUntilTrue:^BOOL{
     return NO;
   } error:&error];
  XCTAssertFalse(didSucceed);
  XCTAssertEqual(error.localizedDescription, expectedMessage);
}

- (void)testSpinUntilNotNil
{
  __block id expectedObject = NSObject.new;
  NSError *error;
  id returnedObject =
  [self.spinner spinUntilNotNil:^id{
    return expectedObject;
  } error:&error];
  XCTAssertNil(error);
  XCTAssertEqual(returnedObject, expectedObject);
}

- (void)testSpinUntilNotNilTimeout
{
  NSError *error;
  id element =
  [self.spinner spinUntilNotNil:^id{
    return nil;
  } error:&error];
  XCTAssertNil(element);
  XCTAssertNotNil(error);
}

@end
