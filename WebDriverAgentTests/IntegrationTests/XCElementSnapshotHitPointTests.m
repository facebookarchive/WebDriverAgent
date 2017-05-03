/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBIntegrationTestCase.h"
#import "FBMathUtils.h"
#import "XCElementSnapshot+FBHitpoint.h"
#import "XCUIElement.h"
#import "XCUIElement+FBUtilities.h"

@interface XCElementSnapshotHitPoint : FBIntegrationTestCase
@end

@implementation XCElementSnapshotHitPoint

- (void)testAccessibilityActivationPoint
{
  [self goToAttributesPage];
  XCUIElement *element = self.testedApplication.buttons[@"not_accessible"];
  XCTAssertTrue(FBPointFuzzyEqualToPoint(element.fb_lastSnapshot.fb_hitPoint, CGPointMake(200, 220), 0.1));
}

@end
