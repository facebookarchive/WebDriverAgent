/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBConfiguration.h"

@interface FBConfigurationTests : XCTestCase

@end

@implementation FBConfigurationTests

- (void)setUp
{
  [super setUp];
  unsetenv("USE_PORT");
  unsetenv("VERBOSE_LOGGING");
}

- (void)testBindingPortDefault
{
  XCTAssertTrue(NSEqualRanges([FBConfiguration bindingPortRange], NSMakeRange(8100, 100)));
}

- (void)testBindingPortEnvironmentOverwrite
{
  setenv("USE_PORT", "1000", 1);
  XCTAssertTrue(NSEqualRanges([FBConfiguration bindingPortRange], NSMakeRange(1000, 1)));
}

- (void)testVerboseLoggingDefault
{
  XCTAssertFalse([FBConfiguration verboseLoggingEnabled]);
}

- (void)testVerboseLoggingEnvironmentOverwrite
{
  setenv("VERBOSE_LOGGING", "YES", 1);
  XCTAssertTrue([FBConfiguration verboseLoggingEnabled]);
}

@end
