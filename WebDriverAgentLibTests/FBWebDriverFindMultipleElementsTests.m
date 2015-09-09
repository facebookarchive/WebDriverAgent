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

@interface FBWebDriverFindMultipleElementsTests : XCTestCase

@end

@implementation FBWebDriverFindMultipleElementsTests

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
          @"identifier": @"1",
          },
        @{
          @"class": @"UIANavigationBar",
          @"name": @"Tab bar",
          @"identifier": @"3",
          @"elements":
            @[
              @{
                @"class": @"UIAButton",
                @"value": @"Second button",
                @"identifier": @"2",
                },
              @{
                @"class": @"UIAStaticText",
                @"label": @"Some text",
                @"identifier": @"5",
                },
              @{
                @"class": @"UIANavigationBar",
                @"value": @"Check In",
                @"identifier": @"4",
                },
              @{
                @"class": @"UIAStaticText",
                @"label": @"Some text",
                @"identifier": @"6",
                },
              ],
          },
        ],
    };
  [[FBWebDriverViewHierarchyMock sharedInstance] mockAppWithWindowDefinitions:@[windowDefinition]];
}

- (void)testFindingByClassName
{
  NSArray *elements = [FBFindElementCommands elementsUsing:@"class name" withValue:@"UIAButton"];
  [self _checkElementsResults:elements againstExpected:@[ @"1", @"2" ]];

  elements = [FBFindElementCommands elementsUsing:@"class name" withValue:@"UIANavigationBar"];
  [self _checkElementsResults:elements againstExpected:@[ @"3", @"4" ]];

  elements = [FBFindElementCommands elementsUsing:@"class name" withValue:@"UIAAlert"];
  [self _checkElementsResults:elements againstExpected:@[]];
}

- (void)testFindingByLinkText
{
  NSArray *elements = [FBFindElementCommands elementsUsing:@"link text" withValue:@"name=Tab bar"];
  [self _checkElementsResults:elements againstExpected:@[ @"3" ]];

  elements = [FBFindElementCommands elementsUsing:@"link text" withValue:@"label=Some text"];
  [self _checkElementsResults:elements againstExpected:@[ @"5", @"6" ]];

  elements = [FBFindElementCommands elementsUsing:@"link text" withValue:@"label=Not found"];
  [self _checkElementsResults:elements againstExpected:@[]];
}

- (void)_checkElementsResults:(NSArray *)results againstExpected:(NSArray *)expected
{
  XCTAssertEqual([expected count], [results count]);
  for (NSInteger i = 0; i < [expected count]; i++) {
    XCTAssertEqualObjects(expected[i], [results[i] identifier]);
  }
}

@end
