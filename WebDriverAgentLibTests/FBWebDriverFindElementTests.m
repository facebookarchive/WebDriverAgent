/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBFindElementCommands.h"
#import "FBWebDriverViewHierarchyMock.h"
#import "UIAElement.h"

@interface FBWebDriverFindElementTests : XCTestCase

@end

@implementation FBWebDriverFindElementTests

- (void)setUp
{
  NSDictionary *windowDefinition =
  @{
    @"class": @"UIAWindow",
    @"value": @"Top window",
    @"elements":
      @[
        @{
          @"class": @"UIAButton",
          @"value": @"Check In",
          },
        @{
          @"class": @"UIANavigationBar",
          @"name": @"Tab bar",
          @"elements":
            @[
              @{
                @"class": @"UIAButton",
                @"value": @"Second button",
                },
              @{
                @"class": @"UIAStaticText",
                @"name": @"Some text",
                },
              @{
                @"class": @"UIAStaticText",
                @"value": @"Check In",
                },
              ],
          },
        ],
    };
  [[FBWebDriverViewHierarchyMock sharedInstance] mockAppWithWindowDefinitions:@[windowDefinition]];
}

- (void)testFindingByClassName
{
  UIAElement *element = [FBFindElementCommands elementUsing:@"class name" withValue:@"UIAButton"];
  XCTAssertEqualObjects([element value], @"Check In");

  element = [FBFindElementCommands elementUsing:@"class name" withValue:@"UIAWindow"];
  XCTAssertEqualObjects([element value], @"Top window");

  element = [FBFindElementCommands elementUsing:@"class name" withValue:@"UIAStaticText"];
  XCTAssertEqualObjects([element name], @"Some text");
}

- (void)testFindingByLinkText
{
  UIAElement *element = [FBFindElementCommands elementUsing:@"link text" withValue:@"value=Check In"];
  XCTAssertEqualObjects([element value], @"Check In");
  XCTAssertEqualObjects([element className], @"UIAButton");

  element = [FBFindElementCommands elementUsing:@"link text" withValue:@"name=Tab bar"];
  XCTAssertEqualObjects([element name], @"Tab bar");
  XCTAssertEqualObjects([element className], @"UIANavigationBar");
}

@end
