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
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 2);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);

  FBClassChainElement *secondElement = [result objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
}

- (void)testValidChainWithStar
{
  NSError *error;
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton[3]/*[4]/*[5]/XCUIElementTypeAlert" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 5);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  
  FBClassChainElement *secondElement = [result objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 3);
  
  FBClassChainElement *thirdElement = [result objectAtIndex:2];
  XCTAssertEqual(thirdElement.type, XCUIElementTypeAny);
  XCTAssertEqual(thirdElement.position, 4);
  
  FBClassChainElement *fourthElement = [result objectAtIndex:3];
  XCTAssertEqual(fourthElement.type, XCUIElementTypeAny);
  XCTAssertEqual(fourthElement.position, 5);
  
  FBClassChainElement *fifthsElement = [result objectAtIndex:4];
  XCTAssertEqual(fifthsElement.type, XCUIElementTypeAlert);
  XCTAssertEqual(fifthsElement.position, 0);
}

- (void)testValidSingleStarChain
{
  NSError *error;
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"*" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 1);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertEqual(firstElement.position, 0);
}

- (void)testValidChainWithNegativeIndex
{
  NSError *error;
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow/XCUIElementTypeButton[-1]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 2);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  
  FBClassChainElement *secondElement = [result objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, -1);
}

- (void)testValidChainWithSinglePredicate
{
  NSError *error;
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`name == 'blabla'`]/XCUIElementTypeButton" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 2);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertNotNil(firstElement.predicate);
  
  FBClassChainElement *secondElement = [result objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertNil(secondElement.predicate);
}

- (void)testValidChainWithMultiplePredicates
{
  NSError *error;
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"XCUIElementTypeWindow[`name == 'blabla'`]/XCUIElementTypeButton[`value == 'blabla'`]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 2);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeWindow);
  XCTAssertEqual(firstElement.position, 1);
  XCTAssertNotNil(firstElement.predicate);
  
  FBClassChainElement *secondElement = [result objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, 0);
  XCTAssertNotNil(secondElement.predicate);
}

- (void)testValidChainWithMultiplePredicatesAndPositions
{
  NSError *error;
  FBClassChain result = [FBClassChainQueryParser parseQuery:@"*[`name == \"к``ири````'лиця\"`][3]/XCUIElementTypeButton[`value == \"blabla\"`][-1]" error:&error];
  XCTAssertNotNil(result);
  XCTAssertEqual(result.count, 2);
  
  FBClassChainElement *firstElement = [result firstObject];
  XCTAssertEqual(firstElement.type, XCUIElementTypeAny);
  XCTAssertEqual(firstElement.position, 3);
  XCTAssertNotNil(firstElement.predicate);
  
  FBClassChainElement *secondElement = [result objectAtIndex:1];
  XCTAssertEqual(secondElement.type, XCUIElementTypeButton);
  XCTAssertEqual(secondElement.position, -1);
  XCTAssertNotNil(secondElement.predicate);
}

- (void)testInvalidChains
{
  NSArray *invalidQueries = @[
    @"/XCUIElementTypeWindow"
    ,@"XCUIElementTypeWindow/"
    ,@"XCUIElementTypeWindow//*"
    ,@"XCUIElementTypeWindow*/*"
    ,@"**"
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
    ,@"XCUIElementTypeWindow[`visible = 1`][`name = \"bla\"`]"
    ,@"XCUIElementTypeWindow[`visible = 1][`name = \"bla\"`]"
    ,@"XCUIElementTypeWindow[`visible = 1]"
    ,@"XCUIElementTypeWindow[``]"
    ,@"XCUIElementTypeWindow[`name = \"bla```bla\"`]"
  ];
  for (NSString *invalidQuery in invalidQueries) {
    NSError *error;
    FBClassChain result = [FBClassChainQueryParser parseQuery:invalidQuery error:&error];
    XCTAssertNil(result);
    XCTAssertNotNil(error);
  }
}

@end
