/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBRoute.h"

@interface FBRouteTests : XCTestCase

@end

@implementation FBRouteTests

- (void)testRouteWithSession
{
  FBRoute *route = [[FBRoute POST:@"/deactivateApp"] respond:nil];
  XCTAssertEqualObjects(route.path, @"/session/:sessionID/deactivateApp");

}

- (void)testRouteWithoutSession
{
  FBRoute *route = [[FBRoute POST:@"/deactivateApp"].withoutSession respond:nil];
  XCTAssertEqualObjects(route.path, @"/deactivateApp");
}

@end
