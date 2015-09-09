/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "FBAlertViewCommands.h"
#import "FBCommandHandler.h"
#import "FBFindElementCommands.h"
#import "FBWebDriverViewHierarchyMock.h"
#import "UIAButton.h"
#import "UIAElement.h"

@interface FBWebDriverAlertTests : XCTestCase

@end

@implementation FBWebDriverAlertTests

- (void)setUp
{
  NSDictionary *windowDefinition =
  @{
    @"class": @"UIAWindow",
    @"elements":
      @[
        @{
          @"class": @"UIAAlert",
          @"elements":
            @[
              @{
                @"class": @"UIAScrollView",
                @"elements":
                  @[
                    @{
                      @"class": @"UIAStaticText",
                      @"name": @"Alert title",
                      @"identifier": @"1",
                      },
                    @{
                      @"class": @"UIAStaticText",
                      @"name": @"Alert body",
                      @"identifier": @"2",
                      },
                    ],
                },
              @{
                @"class": @"UIACollectionView",
                @"elements":
                  @[
                    @{
                      @"class": @"UIACollectionCell",
                      @"elements":
                        @[
                          @{
                            @"class": @"UIAButton",
                            @"name": @"Front button",
                            @"identifier": @"3",
                            },
                          ],
                      },
                    @{
                      @"class": @"UIACollectionCell",
                      @"elements":
                        @[
                          @{
                            @"class": @"UIAButton",
                            @"name": @"Last button",
                            @"identifier": @"4",
                            },
                          ],
                      },
                    ],
                },
              ],
          },
        ],
    };
  [[FBWebDriverViewHierarchyMock sharedInstance] mockAppWithWindowDefinitions:@[windowDefinition]];
  [[FBWebDriverViewHierarchyMock sharedInstance] fixUpAlerts];
}

- (void)testFindingAlertText
{
  NSString *alertText = [FBAlertViewCommands currentAlertText];
  XCTAssertEqualObjects(@"Alert body", alertText);
}

- (void)testTappingFirstButton
{
  NSArray *buttons = [FBFindElementCommands elementsOfClassOnSimulator:UIAClassString(UIAButton)];
  XCTAssertEqual(2, [buttons count]);

  id frontButton = buttons[0];
  id lastButton = buttons[1];

  XCTAssertEqualObjects(@"3", [frontButton identifier]);
  XCTAssertEqualObjects(@"4", [lastButton identifier]);

  [[frontButton expect] tap];
  [[lastButton reject] tap];
  XCTAssertTrue([FBAlertViewCommands dismissAlert]);
  [lastButton verify];
  [frontButton verify];
}

- (void)testTappingSecondButton
{
  NSArray *buttons = [FBFindElementCommands elementsOfClassOnSimulator:UIAClassString(UIAButton)];
  XCTAssertEqual(2, [buttons count]);

  id frontButton = buttons[0];
  id lastButton = buttons[1];

  XCTAssertEqualObjects(@"3", [frontButton identifier]);
  XCTAssertEqualObjects(@"4", [lastButton identifier]);

  [[lastButton expect] tap];
  [[frontButton reject] tap];
  XCTAssertTrue([FBAlertViewCommands acceptAlert]);
  [lastButton verify];
  [frontButton verify];
}

@end
