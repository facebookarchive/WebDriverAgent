/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBFindElementCommands.h"

#import <KissXML/DDXML.h>

#import "FBAlertViewCommands.h"
#import "FBCoreExceptionHandler.h"
#import "FBElementCache.h"
#import "FBElementTypeTransformer.h"
#import "FBRouteRequest.h"
#import "FBWDAMacros.h"
#import "FBElementCache.h"
#import "FBSession.h"
#import "XCElementSnapshot.h"
#import "XCUIApplication.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

static NSString *const kXMLIndexPathKey = @"private_indexPath";

static id<FBResponsePayload> FBNoSuchElementErrorResponseForRequest(FBRouteRequest *request)
{
  NSDictionary *errorDetails = @{
    @"description": @"unable to find an element",
    @"using": request.arguments[@"using"] ?: @"",
    @"value": request.arguments[@"value"] ?: @"",
  };
  return FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, errorDetails);
}

@implementation FBFindElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/element"] respondWithTarget:self action:@selector(handleFindElement:)],
    [[FBRoute POST:@"/elements"] respondWithTarget:self action:@selector(handleFindElements:)],
    [[FBRoute GET:@"/uiaElement/:elementID/getVisibleCells"] respondWithTarget:self action:@selector(handleFindVisibleCells:)],
    [[FBRoute POST:@"/element/:id/element"] respondWithTarget:self action:@selector(handleFindSubElement:)],
    [[FBRoute POST:@"/element/:id/elements"] respondWithTarget:self action:@selector(handleFindSubElements:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleFindElement:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  XCUIElement *element = [self.class elementUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:session.application];
  if (!element) {
    return FBNoSuchElementErrorResponseForRequest(request);
  }
  NSInteger elementID = [request.session.elementCache storeElement:element];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self dictionaryResponseWithElement:element elementID:elementID]);
}

+ (id<FBResponsePayload>)handleFindElements:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSArray *elements = [self.class elementsUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:session.application];
  NSMutableArray *elementsResponse = [[NSMutableArray alloc] init];
  for (XCUIElement *element in elements) {
    NSInteger elementID = [request.session.elementCache storeElement:element];
    [elementsResponse addObject:[self dictionaryResponseWithElement:element elementID:elementID]];
  }
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, elementsResponse);
}

+ (id<FBResponsePayload>)handleFindVisibleCells:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"elementID"] integerValue];
  XCUIElement *collection = [elementCache elementForIndex:elementID];

  NSMutableArray *elementsResponse = [[NSMutableArray alloc] init];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFBVisible == YES"];
  NSArray *elements = [[collection childrenMatchingType:XCUIElementTypeCell] matchingPredicate:predicate].allElementsBoundByIndex;
  for (XCUIElement *element in elements) {
    NSInteger newID = [request.session.elementCache storeElement:element];
    [elementsResponse addObject:[self dictionaryResponseWithElement:element elementID:newID]];
  }
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, elementsResponse);
}

+ (id<FBResponsePayload>)handleFindSubElement:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  XCUIElement *foundElement = [self.class elementUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:element];
  if (!foundElement) {
    return FBNoSuchElementErrorResponseForRequest(request);
  }
  NSInteger elementID = [request.session.elementCache storeElement:foundElement];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self dictionaryResponseWithElement:foundElement elementID:elementID]);
}

+ (id<FBResponsePayload>)handleFindSubElements:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  NSArray *foundElements = [self.class elementsUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:element];

  if (foundElements.count == 0) {
    return FBNoSuchElementErrorResponseForRequest(request);
  }

  NSMutableArray *elementsResponse = [NSMutableArray array];
  for (XCUIElement *iElement in foundElements) {
    NSInteger elementID = [request.session.elementCache storeElement:iElement];
    [elementsResponse addObject:[self dictionaryResponseWithElement:iElement elementID:elementID]];
  }
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, elementsResponse);
}


#pragma mark - Helpers

+ (NSDictionary *)dictionaryResponseWithElement:(XCUIElement *)element elementID:(NSInteger)elementID
{
  return
  @{
    @"ELEMENT": @(elementID),
    @"type": element.wdType,
    @"label" : element.wdLabel ?: [NSNull null],
    };
}

+ (XCUIElement *)elementUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element
{
  FBWDAAssertMainThread();
  return [[self elementsUsing:usingText withValue:value under:element] firstObject];
}

+ (NSArray *)elementsUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element
{
  FBWDAAssertMainThread();

  NSArray *elements;
  const BOOL partialSearch = [usingText isEqualToString:@"partial link text"];
  const BOOL isSearchByIdentifier = ([usingText isEqualToString:@"name"] || [usingText isEqualToString:@"id"] || [usingText isEqualToString:@"accessibility id"]);
  if (partialSearch || [usingText isEqualToString:@"link text"]) {
    NSArray *components = [value componentsSeparatedByString:@"="];
    elements = [self descendantsOfElement:element withProperty:components[0] value:components[1] partial:partialSearch];
  } else if ([usingText isEqualToString:@"class name"]) {
    elements = [self descendantsOfElement:element withClassName:value];
  } else if ([usingText isEqualToString:@"xpath"]) {
    elements = [self descendantsOfElement:element withXPathQuery:value];
  } else if ([usingText isEqualToString:@"predicate string"]) {
      elements = [self descendantsOfElement:element withPredicateString:value];
  } else if (isSearchByIdentifier) {
    elements = [self descendantsOfElement:element withIdentifier:value];
  } else {
    [[NSException exceptionWithName:FBElementAttributeUnknownException reason:[NSString stringWithFormat:@"Invalid locator requested: %@", usingText] userInfo:nil] raise];
  }
  return [FBAlertViewCommands filterElementsObstructedByAlertView:elements];
}


#pragma mark - Search by ClassName

+ (NSArray *)descendantsOfElement:(XCUIElement *)element withClassName:(NSString *)className
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType type = [FBElementTypeTransformer elementTypeWithTypeName:className];
  if (element.elementType == type || type == XCUIElementTypeAny) {
    [result addObject:element];
  }
  [result addObjectsFromArray:[[element descendantsMatchingType:type] allElementsBoundByIndex]];
  return result.copy;
}


#pragma mark - Search by property value

+ (NSArray *)descendantsOfElement:(XCUIElement *)element withProperty:(NSString *)property value:(NSString *)value partial:(BOOL)partialSearch
{
  NSMutableArray *elements = [NSMutableArray array];
  [self descendantsOfElement:element withProperty:property value:value partial:partialSearch results:elements];
  return elements;
}

+ (void)descendantsOfElement:(XCUIElement *)element withProperty:(NSString *)property value:(NSString *)value partial:(BOOL)partialSearch results:(NSMutableArray *)results
{
  if (partialSearch) {
    NSString *text = [element valueForWDAttributeName:property];
    BOOL isString = [text isKindOfClass:[NSString class]];
    if (isString && [text rangeOfString:value].location != NSNotFound) {
      [results addObject:element];
    }
  } else {
    if ([[element valueForWDAttributeName:property] isEqual:value]) {
      [results addObject:element];
    }
  }

  property = wdAttributeNameForAttributeName(property);
  value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
  NSString *operation = partialSearch ?
  [NSString stringWithFormat:@"%@ like '*%@*'", property, value] :
  [NSString stringWithFormat:@"%@ == '%@'", property, value];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:operation];
  XCUIElementQuery *query = [[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = [query allElementsBoundByIndex];
  [results addObjectsFromArray:childElements];
}

#pragma mark - Search by Predicate String
+ (NSArray *)descendantsOfElement:(XCUIElement *)element withPredicateString:(NSString *)predicateString {
    XCUIElementQuery *query = [[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:[NSPredicate predicateWithFormat:predicateString]];
    NSArray *childElements = [query allElementsBoundByIndex];
    return childElements;
}


#pragma mark - Search by xpath

+ (NSArray<XCUIElement *> *)descendantsOfElement:(XCUIElement *)element withXPathQuery:(NSString *)xpathQuery
{
  // XPath will try to match elements only class name, so requesting elements by XCUIElementTypeAny will not work. We should use '*' instead.
  xpathQuery = [xpathQuery stringByReplacingOccurrencesOfString:@"XCUIElementTypeAny" withString:@"*"];
  NSArray *matchingSnapshots = [self descendantsOfElementSnapshot:element.lastSnapshot withXPathQuery:xpathQuery];
  NSArray *allElements = [[element descendantsMatchingType:XCUIElementTypeAny] allElementsBoundByIndex];
  NSArray *matchingElements = [self filterElements:allElements matchingSnapshots:matchingSnapshots];
  return matchingElements;
}

+ (NSArray<XCElementSnapshot *> *)descendantsOfElementSnapshot:(XCElementSnapshot *)elementSnapshot withXPathQuery:(NSString *)xpathQuery
{
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  DDXMLElement *xmlElement = [self XMLElementFromElement:elementSnapshot indexPath:@"top" elementStore:elementStore];
  NSError *error;
  NSArray *xpathNodes = [xmlElement nodesForXPath:xpathQuery error:&error];
  if (![xpathNodes count]) {
    return nil;
  }

  NSMutableArray *matchingSnapshots = [NSMutableArray array];
  for (DDXMLElement *childXMLElement in xpathNodes) {
    XCElementSnapshot *element = [elementStore objectForKey:[[childXMLElement attributeForName:kXMLIndexPathKey] stringValue]];
    if (element) {
      [matchingSnapshots addObject:element];
    }
  }
  return matchingSnapshots;
}

+ (NSArray *)filterElements:(NSArray *)elements matchingSnapshots:(NSArray *)snapshots
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    [elements enumerateObjectsUsingBlock:^(XCUIElement *element, NSUInteger elementIdx, BOOL *stopElementEnum) {
      [element resolve];
      if ([element.lastSnapshot _matchesElement:snapshot]) {
        [matchingElements addObject:element];
        *stopElementEnum = YES;
      }
    }];
  }];
  return matchingElements.copy;
}

+ (DDXMLElement *)XMLElementFromElement:(XCElementSnapshot *)snapshot indexPath:(NSString *)indexPath elementStore:(NSMutableDictionary *)elementStore
{
  DDXMLElement *xmlElement = [[DDXMLElement alloc] initWithName:snapshot.wdType];
  [xmlElement addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:snapshot.wdType]];
  if (snapshot.wdValue) {
    id value = snapshot.wdValue;
    NSString *stringValue;
    if ([value isKindOfClass:[NSValue class]]) {
      stringValue = [value stringValue];
    } else if ([value isKindOfClass:[NSString class]]) {
      stringValue = value;
    } else {
      stringValue = [value description];
    }
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"value" stringValue:stringValue]];
  }
  if (snapshot.wdName) {
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"name" stringValue:snapshot.wdName]];
  }
  if (snapshot.wdLabel) {
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"label" stringValue:snapshot.wdLabel]];
  }
  [xmlElement addAttribute:[DDXMLNode attributeWithName:kXMLIndexPathKey stringValue:indexPath]];

  NSArray *children = snapshot.children;
  for (NSUInteger i  = 0; i < [children count]; i++) {
    XCElementSnapshot *childSnapshot = children[i];
    NSString *newIndexPath = [indexPath stringByAppendingFormat:@",%lu", (unsigned long)i];
    elementStore[newIndexPath] = childSnapshot;
    [xmlElement addChild:[self XMLElementFromElement:childSnapshot indexPath:newIndexPath elementStore:elementStore]];
  }
  return xmlElement;
}


#pragma mark - Search by Accessibility Id

+ (NSArray *)descendantsOfElement:(XCUIElement *)element withIdentifier:(NSString *)accessibilityId
{
  NSMutableArray *result = [NSMutableArray array];
  if (element.identifier == accessibilityId) {
    [result addObject:element];
  }
  NSArray *children = [[[element descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:accessibilityId] allElementsBoundByIndex];
  [result addObjectsFromArray: children];
  return result.copy;
}

@end
