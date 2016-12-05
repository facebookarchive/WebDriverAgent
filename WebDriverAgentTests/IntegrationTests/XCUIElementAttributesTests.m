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
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElement+FBFind.h"
#import "FBElementUtils.h"

@interface XCUIElementAttributesTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *matchingElement;
@end

@implementation XCUIElementAttributesTests

- (void)setUp
{
  [super setUp];
  XCUIElement *testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(testedView.exists);
  [testedView resolve];
  self.matchingElement = [[testedView fb_descendantsMatchingIdentifier:@"Alerts" shouldReturnAfterFirstMatch:YES] firstObject];
  XCTAssertNotNil(self.matchingElement);
}

- (void)verifyGettingAttributeWithShortcut:(NSString *)shortcutName expectedValue:(id)expectedValue
{
  NSString *fullAttributeName = [NSString stringWithFormat:@"wd%@", [NSString stringWithFormat:@"%@%@", [[shortcutName substringToIndex:1] uppercaseString], [shortcutName substringFromIndex:1]]];
  id actualValue = [self.matchingElement fb_valueForWDAttributeName:fullAttributeName];
  id actualShortcutValue = [self.matchingElement fb_valueForWDAttributeName:shortcutName];
  if (nil == expectedValue) {
    XCTAssertNil(actualValue);
    XCTAssertNil(actualShortcutValue);
    return;
  }
  if ([actualValue isKindOfClass:NSString.class]) {
    XCTAssertTrue([actualValue isEqualToString:expectedValue]);
    XCTAssertTrue([actualShortcutValue isEqualToString:expectedValue]);
  } else if ([actualValue isKindOfClass:NSNumber.class]) {
    XCTAssertTrue([actualValue isEqualToNumber:expectedValue]);
    XCTAssertTrue([actualShortcutValue isEqualToNumber:expectedValue]);
  } else {
    XCTAssertEqual(actualValue, expectedValue);
    XCTAssertEqual(actualShortcutValue, expectedValue);
  }
}

- (void)testGetNameAttribute
{
  [self verifyGettingAttributeWithShortcut:@"name" expectedValue:self.matchingElement.wdName];
}

- (void)testGetValueAttribute
{
  [self verifyGettingAttributeWithShortcut:@"value" expectedValue:self.matchingElement.wdValue];
}

- (void)testGetLabelAttribute
{
  [self verifyGettingAttributeWithShortcut:@"label" expectedValue:self.matchingElement.wdLabel];
}

- (void)testGetTypeAttribute
{
  [self verifyGettingAttributeWithShortcut:@"type" expectedValue:self.matchingElement.wdType];
}

- (void)testGetRectAttribute
{
  NSString *shortcutName = @"rect";
  for (NSString *key in @[@"x", @"y", @"width", @"height"]) {
    NSNumber *actualValue = [self.matchingElement fb_valueForWDAttributeName:[FBElementUtils wdAttributeNameForAttributeName:shortcutName]][key];
    NSNumber *actualShortcutValue = [self.matchingElement fb_valueForWDAttributeName:shortcutName][key];
    NSNumber *expectedValue = self.matchingElement.wdRect[key];
    XCTAssertTrue([actualValue isEqualToNumber:expectedValue]);
    XCTAssertTrue([actualShortcutValue isEqualToNumber:expectedValue]);
  }
}

- (void)testGetEnabledAttribute
{
  [self verifyGettingAttributeWithShortcut:@"enabled" expectedValue:[NSNumber numberWithBool:self.matchingElement.wdEnabled]];
}

- (void)testGetAccessibleAttribute
{
  [self verifyGettingAttributeWithShortcut:@"accessible" expectedValue:[NSNumber numberWithBool:self.matchingElement.wdAccessible]];
}

- (void)testGetVisibleAttribute
{
  [self verifyGettingAttributeWithShortcut:@"visible" expectedValue:[NSNumber numberWithBool:self.matchingElement.wdVisible]];
}

- (void)testGetAccessibilityContainerAttribute
{
  [self verifyGettingAttributeWithShortcut:@"accessibilityContainer" expectedValue:[NSNumber numberWithBool:self.matchingElement.wdAccessibilityContainer]];
}

- (void)testGetInvalidAttribute
{
  XCTAssertThrowsSpecificNamed([self verifyGettingAttributeWithShortcut:@"invalid" expectedValue:@"blabla"], NSException, FBUnknownAttributeException);
}

@end
