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
#import "FBRunLoopSpinner.h"
#import "XCUIElement.h"
#import "XCUIElement+FBIsVisible.h"

@interface FBIntegrationTestCase ()
@property (nonatomic, strong) XCUIApplication *testedApplication;
@end

@implementation FBIntegrationTestCase

- (void)setUp
{
  [super setUp];
  self.testedApplication = [XCUIApplication new];
  [self.testedApplication launch];

  // Force resolving XCUIApplication
  [self.testedApplication query];
  [self.testedApplication resolve];
}

- (void)goToAttributesPage
{
  [self.testedApplication.buttons[@"Attributes"] tap];
  [[[FBRunLoopSpinner new]
    interval:1.0]
   spinUntilTrue:^BOOL{
     return self.testedApplication.buttons[@"Button"].fb_isVisible;
   }];
}

@end
