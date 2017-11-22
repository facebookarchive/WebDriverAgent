/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBIntegrationTestCase.h"

#import "XCUIElement.h"
#import "XCUIApplication+FBTouchAction.h"
#import "FBAlert.h"
#import "FBTestMacros.h"
#import "XCUIDevice+FBRotation.h"
#import "FBRunLoopSpinner.h"

@interface FBW3CMultiTouchActionsIntegrationTests : FBIntegrationTestCase

@end


@implementation FBW3CMultiTouchActionsIntegrationTests

- (void)verifyGesture:(NSArray<NSDictionary<NSString *, id> *> *)gesture orientation:(UIDeviceOrientation)orientation
{
  [[XCUIDevice sharedDevice] fb_setDeviceInterfaceOrientation:orientation];
  NSError *error;
  XCTAssertTrue(self.testedApplication.alerts.count == 0);
  XCTAssertTrue([self.testedApplication fb_performW3CTouchActions:gesture elementCache:nil error:&error]);
  FBAssertWaitTillBecomesTrue(self.testedApplication.alerts.count > 0);
}

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToAlertsPage];
  });
}

- (void)tearDown
{
  [super tearDown];
  [[FBAlert alertWithApplication:self.testedApplication] dismissWithError:nil];
}

- (void)testErroneousGestures
{
  NSArray<NSArray<NSDictionary<NSString *, id> *> *> *invalidGestures =
  @[
    // One of the chains has duplicated id
    @[
      @{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"touch"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @0, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
            ],
        },
      @{
        @"type": @"pointer",
        @"id": @"finger1",
        @"parameters": @{@"pointerType": @"touch"},
        @"actions": @[
            @{@"type": @"pointerMove", @"duration": @0, @"x": @1, @"y": @1},
            @{@"type": @"pointerDown"},
            @{@"type": @"pause", @"duration": @100},
            @{@"type": @"pointerUp"},
            ],
        },
      ],
    
    ];
  
  for (NSArray<NSDictionary<NSString *, id> *> *invalidGesture in invalidGestures) {
    NSError *error;
    XCTAssertFalse([self.testedApplication fb_performW3CTouchActions:invalidGesture elementCache:nil  error:&error]);
    XCTAssertNotNil(error);
  }
}

- (void)testSymmetricTwoFingersTap
{
  XCUIElement *element = self.testedApplication.buttons[FBShowAlertButtonName];
  NSArray<NSDictionary<NSString *, id> *> *gesture =
  @[
    @{
      @"type": @"pointer",
      @"id": @"finger1",
      @"parameters": @{@"pointerType": @"touch"},
      @"actions": @[
          @{@"type": @"pointerMove", @"duration": @0, @"origin": element, @"x": @0, @"y": @0},
          @{@"type": @"pointerDown"},
          @{@"type": @"pause", @"duration": @100},
          @{@"type": @"pointerUp"},
          ],
      },
    @{
      @"type": @"pointer",
      @"id": @"finger2",
      @"parameters": @{@"pointerType": @"touch"},
      @"actions": @[
          @{@"type": @"pointerMove", @"duration": @0, @"origin": element, @"x": @0, @"y": @0},
          @{@"type": @"pointerDown"},
          @{@"type": @"pause", @"duration": @100},
          @{@"type": @"pointerUp"},
          ],
      },
    ];
  
  [self verifyGesture:gesture orientation:UIDeviceOrientationPortrait];
}

@end

