/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "XCUIElementDouble.h"
#import "FBClassChainQueryParser.h"

@interface FBClassChainTests : XCTestCase
@end

@implementation FBClassChainTests

- (void)testValidChain
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertFalse(firstElement.isDescendant);

  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithStar
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton[3]/*[4]/*[5]/XCUIElementTypeAlert" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 5);
  
    FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 3);
  XCTAssertFalse(secondElement.isDescendant);
  
  FBClassChainItem *thirdElement = [result.elements objectAtIndex:2];
  XCTAssertEqual(thirdElement.type, XCUIElementTypeAny);
  XCTAssertEqual(thirdElement.position, 4);
  XCTAssertFalse(thirdElement.isDescendant);
  
  FBClassChainItem *fourthElement = [result.elements objectAtIndex:3];
  XCTAssertEqual(fourthElement.type, XCUIElementTypeAny);
  XCTAssertEqual(fourthElement.position, 5);
  XCTAssertFalse(fourthElement.isDescendant);
  
  FBClassChainItem *fifthsElement = [result.elements objectAtIndex:4];
  XCTAssertEqual(fifthsElement.type, XCUIElementTypeAlert);
  XCTAssertEqual(fifthsElement.position, 0);
  XCTAssertFalse(fifthsElement.isDescendant);
}

- (void)testValidSingleStarChain
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"*" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 1);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertEqual(firstElement.position, 0);
  XCTAssertFalse(firstElement.isDescendant);
}

- (void)testValidSingleStarIndirectChain
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/*/*/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 3);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeAny);
  XCTAssertEqual(secondElement.position, 1);
  XCTAssertFalse(secondElement.isDescendant);
  
  FBClassChainItem *thirdElement = [result.elements objectAtIndex:2];
  XCTAssertEqual(thirdElement.type, XCUIElementTypeButton);
  XCTAssertEqual(thirdElement.position, 0);
  XCTAssertFalse(thirdElement.isDescendant);
}

- (void)testValidDoubleIndirectChainAndStar
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeButton/**/*" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeButton);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeAny);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertTrue(secondElement.isDescendant);
}

- (void)testValidDoubleIndirectChainAndClassName
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeButton/**/XCUIElementTypeImage" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeButton);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeImage);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertTrue(secondElement.isDescendant);
}

- (void)testValidChainWithNegativeIndex
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton[-1]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertEqual(firstElement.predicates.count, 0);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, -1);
  XCTAssertEqual(secondElement.predicates.count, 0);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithSinglePredicate
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`name == 'blabla'`]/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertEqual(secondElement.predicates.count, 0);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithMultiplePredicates
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`name == 'blabla'`]/XCUIElementTypeButton[`value == 'blabla'`]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertEqual(secondElement.predicates.count, 1);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithIndirectSearchAndPredicates
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeTable[`name == 'blabla'`][10]/**/XCUIElementTypeButton[`value == 'blabla'`]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeTable);
  XCTAssertEqual(firstElement.position, 10);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertTrue(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertEqual(secondElement.predicates.count, 1);
  XCTAssertTrue(secondElement.isDescendant);
}

- (void)testValidChainWithMultiplePredicatesAndPositions
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"*[`name == \"к``ири````'лиця\"`][3]/XCUIElementTypeButton[`value == \"blabla\"`][-1]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 2);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertEqual(firstElement.position, 3);
  XCTAssertEqual(firstElement.predicates.count, 1);
  XCTAssertFalse(firstElement.isDescendant);
  
  FBClassChainItem *secondElement = [result.elements objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, -1);
  XCTAssertEqual(secondElement.predicates.count, 1);
  XCTAssertFalse(secondElement.isDescendant);
}

- (void)testValidChainWithDescendantPredicate
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeTable[$type == 'XCUIElementTypeImage' AND name == 'olala'$][`name == 'blabla'`][10]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 1);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeTable);
  XCTAssertEqual(firstElement.position, 10);
  XCTAssertEqual(firstElement.predicates.count, 2);
  XCTAssertTrue(firstElement.isDescendant);
}

- (void)testValidChainWithMultipleDescendantPredicates
{
  NSError *error;
  FBClassChain *result = [FBClassChainQueryParser parseQuery:@"**/XCUIElementTypeTable[$type == 'XCUIElementTypeImage' AND name == 'olala'$][`value == 'peace'`][$value == 'yolo'$][`name == 'blabla'`][10]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.elements.count, 1);
  
  FBClassChainItem *firstElement = [result.elements firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeTable);
  XCTAssertEqual(firstElement.position, 10);
  XCTAssertEqual(firstElement.predicates.count, 4);
  XCTAssertTrue(firstElement.isDescendant);
}

- (void)testInvalidChains
{
  NSArray *invalidQueries = @[
    @"/XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow/"
    ,@"XCUIElementTypeWindow//*"
    ,@"XCUIElementTypeWindow*/*"
    ,@"**"
    ,@"***"
    ,@"**/*/**"
    ,@"/**"
    ,@"XCUIElementTypeWindow/**"
    ,@"**[1]/XCUIElementTypeWindow"
    ,@"**[`name == '1'`]/XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow[0]"
    ,@"XCUIElementTypeWindow[1][1]"
    ,@"blabla"
    ,@"XCUIElementTypeWindow/blabla"
    ,@" XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow[ 2 ]"
    ,@"XCUIElementTypeWindow[[2]"
    ,@"XCUIElementTypeWindow[2]]"
    ,@"XCUIElementType[Window[2]]"
    ,@"XCUIElementTypeWindow[visible = 1]"
    ,@"XCUIElementTypeWindow[1][`visible = 1`]"
    ,@"XCUIElementTypeWindow[1] [`visible = 1`]"
    ,@"XCUIElementTypeWindow[ `visible = 1`]"
    ,@"XCUIElementTypeWindow[`visible = 1][`name = \"bla\"`]"
    ,@"XCUIElementTypeWindow[`visible = 1]"
    ,@"XCUIElementTypeWindow[$visible = 1]"
    ,@"XCUIElementTypeWindow[``]"
    ,@"XCUIElementTypeWindow[$$]"
    ,@"XCUIElementTypeWindow[`name = \"bla```bla\"`]"
    ,@"XCUIElementTypeWindow[$name = \"bla$$$bla\"$]"
  ];
  for (NSString *invalidQuery in invalidQueries) {
    NSError *error;
    FBClassChain *result = [FBClassChainQueryParser parseQuery:invalidQuery error:&error];
    XCTAssertNil(result);
    XCTAssertNotNil(error);
  }
}

@end
