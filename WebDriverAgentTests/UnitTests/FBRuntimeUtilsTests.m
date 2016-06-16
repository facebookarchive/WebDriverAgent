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
#import "XCTestPrivateSymbols.h"

@protocol FBMagicProtocol <NSObject>
@end

const NSString *FBRuntimeUtilsTestsConstString = @"FBRuntimeUtilsTestsConstString";

@interface FBRuntimeUtilsTests : XCTestCase <FBMagicProtocol>
@end

@implementation FBRuntimeUtilsTests

- (void)testClassesThatConformsToProtocol
{
  XCTAssertEqualObjects(@[self.class], FBClassesThatConformsToProtocol(@protocol(FBMagicProtocol)));
}

- (void)testRetrievingFrameworkSymbols
{
  NSString *binaryPath = [NSBundle bundleForClass:self.class].executablePath;
  NSString *symbolPointer = *(NSString*__autoreleasing*)FBRetrieveSymbolFromBinary(binaryPath.UTF8String, "FBRuntimeUtilsTestsConstString");
  XCTAssertNotNil(symbolPointer);
  XCTAssertEqualObjects(symbolPointer, FBRuntimeUtilsTestsConstString);
}

- (void)testXCTestSymbols
{
  XCTAssertTrue(XCDebugLogger != NULL);
  XCTAssertTrue(XCSetDebugLogger != NULL);
  XCTAssertNotNil(FB_XCAXAIsVisibleAttribute);
  XCTAssertNotNil(FB_XCAXAIsElementAttribute);
}

@end
