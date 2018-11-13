/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBTVIntegrationTestCase.h"
#import "FBMathUtils.h"
#import "XCElementSnapshot+FBHitpoint.h"
#import "XCUIElement.h"
#import "XCUIElement+FBUtilities.h"

@interface TVXCElementSnapshotHitPoint : FBTVIntegrationTestCase
@end

@implementation TVXCElementSnapshotHitPoint

- (void)testAccessibilityActivationPoint
{
  [self launchApplication];
  [self goToAttributesPage];
  XCUIElement *element = self.testedApplication.otherElements[@"testView"];
  NSError *error;
  FBElementHitPoint *hitpoint = [element.fb_lastSnapshot fb_hitPoint:&error];
  XCTAssertNotNil(hitpoint);
  XCTAssertTrue(FBPointFuzzyEqualToPoint(hitpoint.point, CGPointMake(25, 25), 0.1));
}

@end
