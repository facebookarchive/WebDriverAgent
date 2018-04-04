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
#import "FBConfiguration.h"
#import "FBResponsePayload.h"

@interface XCUIElementAttributesTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *matchingElement;
@end

@implementation XCUIElementAttributesTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
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

- (void)testGetUidAttribute
{
  [self verifyGettingAttributeWithShortcut:@"UID" expectedValue:self.matchingElement.wdUID];
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

@interface XCUIElementFBFindTests_CompactResponses : FBIntegrationTestCase
@end


@implementation XCUIElementFBFindTests_CompactResponses

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testCompactResponseYes
{
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", YES);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqual(fields.count, 1);
}

- (void)testCompactResponseNo
{
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", NO);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqualObjects(fields[@"type"], @"XCUIElementTypeButton");
  XCTAssertEqualObjects(fields[@"label"], @"Alerts");
  XCTAssertEqual(fields.count, 3);
}

@end


@interface XCUIElementFBFindTests_ResponseFields : FBIntegrationTestCase
@end

@implementation XCUIElementFBFindTests_ResponseFields

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
}

- (void)testCompactResponseYesWithResponseAttributesSet
{
  [FBConfiguration setElementResponseAttributes:@"name,text,enabled"];
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", YES);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqual(fields.count, 1);
}

- (void)testCompactResponseNoWithResponseAttributesSet
{
  [FBConfiguration setElementResponseAttributes:@"name,text,enabled"];
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", NO);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqualObjects(fields[@"name"], @"XCUIElementTypeButton");
  XCTAssertEqualObjects(fields[@"text"], @"Alerts");
  XCTAssertEqualObjects(fields[@"enabled"], @(YES));
  XCTAssertEqual(fields.count, 4);
}

- (void)testInvalidAttribute
{
  [FBConfiguration setElementResponseAttributes:@"invalid_field,name"];
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", NO);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqualObjects(fields[@"name"], @"XCUIElementTypeButton");
  XCTAssertEqual(fields.count, 2);
}

- (void)testKnownAttributes
{
  [FBConfiguration setElementResponseAttributes:@"name,type,label,text,rect,enabled,displayed,selected"];
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", NO);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqualObjects(fields[@"name"], @"XCUIElementTypeButton");
  XCTAssertEqualObjects(fields[@"type"], @"XCUIElementTypeButton");
  XCTAssertEqualObjects(fields[@"label"], @"Alerts");
  XCTAssertEqualObjects(fields[@"text"], @"Alerts");
  XCTAssertTrue(matchesRegex([fields[@"rect"] description], @"\\{\\s*height = [0-9]+;\\s*width = [0-9]+;\\s*x = [0-9]+;\\s*y = [0-9]+;\\s*\\}"));
  XCTAssertEqualObjects(fields[@"enabled"], @(YES));
  XCTAssertEqualObjects(fields[@"displayed"], @(YES));
  XCTAssertEqualObjects(fields[@"selected"], @(NO));
  XCTAssertEqual(fields.count, 9);
}

- (void)testArbitraryAttributes
{
  [FBConfiguration setElementResponseAttributes:@"attribute/name,attribute/value"];
  XCUIElement *alertsButton = self.testedApplication.buttons[@"Alerts"];
  NSDictionary *fields = FBDictionaryResponseWithElement(alertsButton, @"DUMMY", NO);
  XCTAssertEqualObjects(fields[@"ELEMENT"], @"DUMMY");
  XCTAssertEqualObjects(fields[@"attribute/name"], @"Alerts");
  XCTAssertEqualObjects(fields[@"attribute/value"], [NSNull null]);
  XCTAssertEqual(fields.count, 3);
}

static BOOL matchesRegex(NSString *target, NSString *pattern) {
  if (!target)
    return NO;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
  return [regex numberOfMatchesInString:target options:0 range:NSMakeRange(0, target.length)] == 1;
}

@end
