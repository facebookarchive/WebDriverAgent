/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBErrorBuilder.h"

@interface FBErrorBuilderTests : XCTestCase
@end

@implementation FBErrorBuilderTests

- (void)testErrorWithDescription
{
  NSString *expectedDescription = @"Magic description";
  NSError *error =
  [[[FBErrorBuilder builder]
    withDescription:expectedDescription]
   build];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects([error localizedDescription], expectedDescription);
}

- (void)testErrorWithDescriptionFormat
{
  NSError *error =
  [[[FBErrorBuilder builder]
    withDescriptionFormat:@"Magic %@", @"bob"]
   build];
  XCTAssertEqualObjects([error localizedDescription], @"Magic bob");
}

- (void)testInnerError
{
  NSError *innerError = [NSError errorWithDomain:@"Domain" code:1 userInfo:@{}];
  NSError *error =
  [[[FBErrorBuilder builder]
    withInnerError:innerError]
   build];
  XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey], innerError);
}

- (void)testBuildWithError
{
  NSString *expectedDescription = @"Magic description";
  NSError *error;
  BOOL result =
  [[[FBErrorBuilder builder]
    withDescription:expectedDescription]
   buildError:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.localizedDescription, expectedDescription);
  XCTAssertFalse(result);
}

@end
