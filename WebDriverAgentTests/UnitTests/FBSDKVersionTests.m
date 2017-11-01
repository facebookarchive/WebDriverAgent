/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBRuntimeUtils.h"

@interface FBSDKVersionTests : XCTestCase
@property (nonatomic, readonly) NSString *currentSDKVersion;
@property (nonatomic, readonly) NSString *lowerSDKVersion;
@property (nonatomic, readonly) NSString *higherSDKVersion;
@end

@implementation FBSDKVersionTests

- (void)setUp
{
  [super setUp];
  NSDictionary *bundleDict = [[NSBundle mainBundle] infoDictionary];
  [bundleDict setValue:@"11.0" forKey:@"DTSDKName"];
  _currentSDKVersion = FBSDKVersion();
  _lowerSDKVersion = [NSString stringWithFormat:@"%@", @((int)[self.currentSDKVersion doubleValue] - 1)];
  _higherSDKVersion = [NSString stringWithFormat:@"%@", @((int)[self.currentSDKVersion doubleValue] + 1)];
}

- (void)testIsSDKVersionLessThanOrEqualTo
{
  XCTAssertTrue(isSDKVersionLessThanOrEqualTo(self.higherSDKVersion));
  XCTAssertFalse(isSDKVersionLessThanOrEqualTo(self.lowerSDKVersion));
  XCTAssertTrue(isSDKVersionLessThanOrEqualTo(self.currentSDKVersion));
}

- (void)testIsSDKVersionLessThan
{
  XCTAssertTrue(isSDKVersionLessThan(self.higherSDKVersion));
  XCTAssertFalse(isSDKVersionLessThan(self.lowerSDKVersion));
  XCTAssertFalse(isSDKVersionLessThan(self.currentSDKVersion));
}

- (void)testIsSDKVersionEqualTo
{
  XCTAssertFalse(isSDKVersionEqualTo(self.higherSDKVersion));
  XCTAssertFalse(isSDKVersionEqualTo(self.lowerSDKVersion));
  XCTAssertTrue(isSDKVersionEqualTo(self.currentSDKVersion));
}

- (void)testIsSDKVersionGreaterThanOrEqualTo
{
  XCTAssertFalse(isSDKVersionGreaterThanOrEqualTo(self.higherSDKVersion));
  XCTAssertTrue(isSDKVersionGreaterThanOrEqualTo(self.lowerSDKVersion));
  XCTAssertTrue(isSDKVersionGreaterThanOrEqualTo(self.currentSDKVersion));
}

- (void)testIsSDKVersionGreaterThan
{
  XCTAssertFalse(isSDKVersionGreaterThan(self.higherSDKVersion));
  XCTAssertTrue(isSDKVersionGreaterThan(self.lowerSDKVersion));
  XCTAssertFalse(isSDKVersionGreaterThan(self.currentSDKVersion));
}

@end
