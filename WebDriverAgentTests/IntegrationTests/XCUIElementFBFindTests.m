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
#import "FBElementUtils.h"
#import "FBTestMacros.h"
#import "XCUIElement.h"
#import "XCUIElement+FBFind.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBClassChain.h"
#import "FBXPath.h"
#import "FBXCodeCompatibility.h"

@interface XCUIElementFBFindTests : FBIntegrationTestCase
@property (nonatomic, strong) XCUIElement *testedView;
@end

@implementation XCUIElementFBFindTests

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
  });
  self.testedView = self.testedApplication.otherElements[@"MainView"];
  XCTAssertTrue(self.testedView.exists);
  [self.testedView resolve];
}

- (void)testDescendantsWithClassName
{
  NSSet<NSString *> *expectedLabels = [NSSet setWithArray:@[
    @"Alerts",
    @"Attributes",
    @"Scrolling",
    @"Deadlock app",
  ]];
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingClassName:@"XCUIElementTypeButton" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, expectedLabels.count);
  NSArray<NSString *> *labels = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.label"];
  XCTAssertEqualObjects([NSSet setWithArray:labels], expectedLabels);

  NSArray<NSNumber *> *types = [matchingSnapshots valueForKeyPath:@"@distinctUnionOfObjects.elementType"];
  XCTAssertEqual(types.count, 1, @"matchingSnapshots should contain only one type");
  XCTAssertEqualObjects(types.lastObject, @(XCUIElementTypeButton), @"matchingSnapshots should contain only one type");
}

- (void)testSingleDescendantWithClassName
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingClassName:@"XCUIElementTypeButton" shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
}

- (void)testDescendantsWithIdentifier
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingIdentifier:@"Alerts" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testSingleDescendantWithIdentifier
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingIdentifier:@"Alerts" shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testSingleDescendantWithMissingIdentifier
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingIdentifier:@"blabla" shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matchingSnapshots.count, 0);
}

- (void)testDescendantsWithXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton[@label='Alerts']" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testSelfWithXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedApplication fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeApplication" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeApplication);
}

- (void)testSingleDescendantWithXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedApplication fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton" shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCUIElement *matchingSnapshot = [matchingSnapshots firstObject];
  XCTAssertNotNil(matchingSnapshot);
  XCTAssertEqual(matchingSnapshot.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshot.label, @"Alerts");
}

- (void)testSingleDescendantWithXPathQueryNoMatches
{
  XCUIElement *matchingSnapshot = [[self.testedView fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButtonnn" shouldReturnAfterFirstMatch:YES] firstObject];
  XCTAssertNil(matchingSnapshot);
}

- (void)testSingleLastDescendantWithXPathQuery
{
  XCUIElement *matchingSnapshot = [[self.testedView fb_descendantsMatchingXPathQuery:@"(//XCUIElementTypeButton)[last()]" shouldReturnAfterFirstMatch:YES] firstObject];
  XCTAssertNotNil(matchingSnapshot);
  XCTAssertEqual(matchingSnapshot.elementType, XCUIElementTypeButton);
}

- (void)testDescendantsWithXPathQueryNoMatches
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton[@label='Alerts1']" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 0);
}

- (void)testDescendantsWithComplexXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingXPathQuery:@"//*[@label='Scrolling']/preceding::*[boolean(string(@label))]" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 3);
}

- (void)testDescendantsWithWrongXPathQuery
{
  XCTAssertThrowsSpecificNamed([self.testedView fb_descendantsMatchingXPathQuery:@"//*[blabla(@label, Scrolling')]" shouldReturnAfterFirstMatch:NO],
                               NSException, XCElementSnapshotInvalidXPathException);
}

- (void)testFirstDescendantWithWrongXPathQuery
{
  XCTAssertThrowsSpecificNamed([self.testedView fb_descendantsMatchingXPathQuery:@"//*[blabla(@label, Scrolling')]" shouldReturnAfterFirstMatch:YES],
                               NSException, XCElementSnapshotInvalidXPathException);
}

- (void)testVisibleDescendantWithXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeButton[@name='Alerts' and @enabled='true' and @visible='true']" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertTrue(matchingSnapshots.lastObject.isEnabled);
  XCTAssertTrue(matchingSnapshots.lastObject.fb_isVisible);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithPredicateString
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label = 'Alerts'"];
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingPredicate:predicate shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testSelfWithPredicateString
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == 'XCUIElementTypeApplication'"];
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedApplication fb_descendantsMatchingPredicate:predicate shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeApplication);
}

- (void)testSingleDescendantWithPredicateString
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = 'XCUIElementTypeButton'"];
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingPredicate:predicate shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
}

- (void)testDescendantsWithPropertyStrict
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingProperty:@"label" value:@"Alert" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 0);
  matchingSnapshots = [self.testedView fb_descendantsMatchingProperty:@"label" value:@"Alerts" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testGlobalWithPropertyStrict
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedApplication fb_descendantsMatchingProperty:@"label" value:@"Alert" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 0);
  matchingSnapshots = [self.testedApplication fb_descendantsMatchingProperty:@"label" value:@"Alerts" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithPropertyPartial
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingProperty:@"label" value:@"Alerts" partialSearch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(matchingSnapshots.lastObject.label, @"Alerts");
}

- (void)testDescendantsWithClassChain
{
  NSArray<XCUIElement *> *matchingSnapshots;
  matchingSnapshots = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow/*/*[2]/*/*/XCUIElementTypeButton" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 4);
  for (XCUIElement *matchingSnapshot in matchingSnapshots) {
    XCTAssertEqual(matchingSnapshot.elementType, XCUIElementTypeButton);
  }
}

- (void)testDescendantsWithClassChainAndPredicates
{
  NSArray<XCUIElement *> *matchingSnapshots;
  matchingSnapshots = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow/*/*[2]/*/*/XCUIElementTypeButton[`label BEGINSWITH 'A'`]" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 2);
  XCTAssertEqualObjects([matchingSnapshots firstObject].label, @"Alerts");
  XCTAssertEqualObjects([matchingSnapshots lastObject].label, @"Attributes");
}

- (void)testDescendantsWithIndirectClassChainAndPredicates
{
  NSArray<XCUIElement *> *simpleQueryMatches = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow/*/*[2]/*/*/XCUIElementTypeButton[`label BEGINSWITH 'A'`]" shouldReturnAfterFirstMatch:NO];
  NSArray<XCUIElement *> *deepQueryMatches = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow/**/XCUIElementTypeButton[`label BEGINSWITH 'A'`]" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(simpleQueryMatches.count, deepQueryMatches.count);
  XCTAssertEqualObjects([simpleQueryMatches firstObject].label, [deepQueryMatches firstObject].label);
  XCTAssertEqualObjects([simpleQueryMatches lastObject].label, [deepQueryMatches lastObject].label);
}

- (void)testClassChainWithDescendantPredicate
{
  NSArray<XCUIElement *> *simpleQueryMatches = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow/*/*[2]" shouldReturnAfterFirstMatch:NO];
  NSArray<XCUIElement *> *predicateQueryMatches = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow/*/*[$type == 'XCUIElementTypeButton' AND label BEGINSWITH 'A'$]" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(simpleQueryMatches.count, predicateQueryMatches.count);
  XCTAssertEqual([simpleQueryMatches firstObject].elementType, [predicateQueryMatches firstObject].elementType);
  XCTAssertEqual([simpleQueryMatches lastObject].elementType, [predicateQueryMatches lastObject].elementType);
}

- (void)testSingleDescendantWithComplexIndirectClassChain
{
  NSArray<XCUIElement *> *queryMatches = [self.testedApplication fb_descendantsMatchingClassChain:@"**/*/XCUIElementTypeButton[2]" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(queryMatches.count, 1);
  XCTAssertEqual(queryMatches.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertEqualObjects(queryMatches.lastObject.label, @"Deadlock app");
}

- (void)testSingleDescendantWithComplexIndirectClassChainAndZeroMatches
{
  NSArray<XCUIElement *> *queryMatches = [self.testedApplication fb_descendantsMatchingClassChain:@"**/*/XCUIElementTypeWindow" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(queryMatches.count, 0);
}

- (void)testDescendantsWithClassChainAndPredicatesAndIndexes
{
  NSArray<XCUIElement *> *matchingSnapshots;
  matchingSnapshots = [self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow[`name != 'bla'`]/*/*[2]/*/*/XCUIElementTypeButton[`label BEGINSWITH \"A\"`][1]" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqualObjects([matchingSnapshots firstObject].label, @"Alerts");
}

- (void)testSingleDescendantWithClassChain
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedView fb_descendantsMatchingClassChain:@"XCUIElementTypeButton" shouldReturnAfterFirstMatch:YES];
  
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertTrue([matchingSnapshots.lastObject.label isEqualToString:@"Alerts"]);
}

- (void)testSingleDescendantWithClassChainAndNegativeIndex
{
  NSArray<XCUIElement *> *matchingSnapshots;
  matchingSnapshots = [self.testedView fb_descendantsMatchingClassChain:@"XCUIElementTypeButton[-1]" shouldReturnAfterFirstMatch:YES];
  
  XCTAssertEqual(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeButton);
  XCTAssertTrue([matchingSnapshots.lastObject.label isEqualToString:@"Scrolling"]);
  
  matchingSnapshots = [self.testedView fb_descendantsMatchingClassChain:@"XCUIElementTypeButton[-10]" shouldReturnAfterFirstMatch:YES];
  XCTAssertEqual(matchingSnapshots.count, 0);
}

- (void)testInvalidQueryWithClassChain
{
  XCTAssertThrowsSpecificNamed([self.testedView fb_descendantsMatchingClassChain:@"XCUIElementTypeBlabla" shouldReturnAfterFirstMatch:YES], NSException, FBClassChainQueryParseException);
}

- (void)testClassChainWithInvalidPredicate
{
  XCTAssertThrowsSpecificNamed([self.testedApplication fb_descendantsMatchingClassChain:@"XCUIElementTypeWindow[`bla != 'bla'`]" shouldReturnAfterFirstMatch:NO],
                               NSException, FBUnknownAttributeException);;
}

@end

@interface XCUIElementFBFindTests_AttributesPage : FBIntegrationTestCase
@end
@implementation XCUIElementFBFindTests_AttributesPage

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToAttributesPage];
  });
}

- (void)testNestedQueryWithClassChain
{
  FBAssertWaitTillBecomesTrue(self.testedApplication.buttons[@"Button"].fb_isVisible);
  XCUIElement *datePicker = [self.testedApplication descendantsMatchingType:XCUIElementTypeDatePicker].fb_firstMatch;
  NSArray<XCUIElement *> *matches = [datePicker fb_descendantsMatchingClassChain:@"XCUIElementTypeOther" shouldReturnAfterFirstMatch:NO];
  XCTAssertEqual(matches.count, 1);
  XCTAssertEqual([matches firstObject].elementType, XCUIElementTypeOther);
}

@end

@interface XCUIElementFBFindTests_ScrollPage : FBIntegrationTestCase
@end
@implementation XCUIElementFBFindTests_ScrollPage

- (void)setUp
{
  [super setUp];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self launchApplication];
    [self goToScrollPageWithCells:YES];
  });
}

- (void)testInvisibleDescendantWithXPathQuery
{
  NSArray<XCUIElement *> *matchingSnapshots = [self.testedApplication fb_descendantsMatchingXPathQuery:@"//XCUIElementTypeStaticText[@visible='false']" shouldReturnAfterFirstMatch:NO];
  XCTAssertGreaterThan(matchingSnapshots.count, 1);
  XCTAssertEqual(matchingSnapshots.lastObject.elementType, XCUIElementTypeStaticText);
  XCTAssertFalse(matchingSnapshots.lastObject.fb_isVisible);
}

@end
