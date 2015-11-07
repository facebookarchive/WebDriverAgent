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
#import "FBElementCache.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCElementSnapshot.h"
#import "XCUIApplication.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+UIAClassMapping.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

static NSString *const kXMLIndexPathKey = @"private_indexPath";

@implementation FBFindElementCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"POST@/session/:sessionID/element" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [self.class elementUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:request.session.application];
      if (!element) {
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an element"));
        return;
      }
      NSInteger elementID = [request.session.elementCache storeElement:element];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self dictionaryResponseWithElement:element elementID:elementID]));
    },
    @"POST@/session/:sessionID/elements" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSArray *elements = [self.class elementsUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:request.session.application];
      NSMutableArray *elementsResponse = [[NSMutableArray alloc] init];
      for (XCUIElement *element in elements) {
        NSInteger elementID = [request.session.elementCache storeElement:element];
        [elementsResponse addObject:[self dictionaryResponseWithElement:element elementID:elementID]];
      }
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, elementsResponse));
    },
    @"GET@/session/:sessionID/uiaElement/:elementID/getVisibleCells" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"elementID"] integerValue];
      XCUIElement *collection = [request.session.elementCache elementForIndex:elementID];

      NSMutableArray *elementsResponse = [[NSMutableArray alloc] init];
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFBVisible == YES"];
      NSArray *elements = [[collection childrenMatchingType:XCUIElementTypeCell] matchingPredicate:predicate].allElementsBoundByIndex;
      for (XCUIElement *element in elements) {
        NSInteger newID = [request.session.elementCache storeElement:element];
        [elementsResponse addObject:[self dictionaryResponseWithElement:element elementID:newID]];
      }
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, elementsResponse));
    },
    @"POST@/session/:sessionID/element/:id/element" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      XCUIElement *foundElement = [self.class elementUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:element];
      if (!foundElement) {
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an element"));
        return;
      }
      NSInteger elementID = [request.session.elementCache storeElement:foundElement];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self dictionaryResponseWithElement:foundElement elementID:elementID]));
    },
    @"POST@/session/:sessionID/element/:id/elements" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      NSArray *foundElements = [self.class elementsUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:element];

      if (foundElements.count == 0) {
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoSuchElement, @"unable to find an element"));
        return;
      }

      NSMutableArray *elementsResponse = [NSMutableArray array];
      for (XCUIElement *iElement in foundElements) {
        NSInteger elementID = [request.session.elementCache storeElement:iElement];
        [elementsResponse addObject:[self dictionaryResponseWithElement:iElement elementID:elementID]];
      }
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, elementsResponse));
    },
  };
}


#pragma mark - Helpers

+ (NSDictionary *)dictionaryResponseWithElement:(XCUIElement *)element elementID:(NSInteger)elementID
{
  return
  @{
    @"ELEMENT": @(elementID),
    @"type": element.UIAClassName,
    @"label" : element.label ?: [NSNull null],
    };
}

+ (XCUIElement *)elementUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element
{
  return [[self elementsUsing:usingText withValue:value under:element] firstObject];
}

+ (NSArray *)elementsUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element
{
  NSArray *elements;
  BOOL partialSearch = [usingText isEqualToString:@"partial link text"];
  if (partialSearch || [usingText isEqualToString:@"link text"]) {
    NSArray *components = [value componentsSeparatedByString:@"="];
    elements = [self descendantsOfElement:element withProperty:components[0] value:components[1] partial:partialSearch];
  } else if ([usingText isEqualToString:@"class name"]) {
    elements = [self descendantsOfElement:element withClassName:value];
  } else if ([usingText isEqualToString:@"xpath"]) {
    elements = [self descendantsOfElement:element withXPathQuery:value];
  } else if ([usingText isEqualToString:@"accessibility id"]) {
      elements = [self descendantsOfElement:element withIdentifier:value];
  }
  return [FBAlertViewCommands filterElementsObstructedByAlertView:elements];
}


#pragma mark - Search by ClassName

+ (NSArray *)descendantsOfElement:(XCUIElement *)element withClassName:(NSString *)className
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType type = [XCUIElement elementTypeWithUIAClassName:className];
  if (element.elementType == type) {
    [result addObject:result];
  }
  [result addObjectsFromArray:[[element descendantsMatchingType:type] allElementsBoundByIndex]];
  return result.copy;
}

#pragma mark - Search by Accessibility Id

+ (NSArray *)descendantsOfElement:(XCUIElement *)element withIdentifier:(NSString *)accessibilityId
{
    NSMutableArray *result = [NSMutableArray array];
    if (element.identifier == accessibilityId) {
        [result addObject:result];
    }
    NSArray *children = [[[element descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:accessibilityId] allElementsBoundByIndex];
    [result addObjectsFromArray: children];
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
  property = xctAttributeNameForWDAttributeName(property);

  value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
  NSString *operation = partialSearch ?
  [NSString stringWithFormat:@"%@ like '*%@*'", property, value] :
  [NSString stringWithFormat:@"%@ == '%@'", property, value];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:operation];
  XCUIElementQuery *query = [[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = [query allElementsBoundByIndex];
  [results addObjectsFromArray:childElements];
}


#pragma mark - Search by xpath

+ (NSArray *)descendantsOfElement:(XCUIElement *)element withXPathQuery:(NSString *)xpathQuery
{
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  DDXMLElement *xmlElement = [self XMLElementFromElement:element.lastSnapshot indexPath:@"top" elementStore:elementStore];
  NSError *error;
  NSArray *xpathNodes = [xmlElement nodesForXPath:xpathQuery error:&error];
  if (![xpathNodes count]) {
    return nil;
  }

  NSMutableArray *matchingSnapshots = [NSMutableArray array];
  for (DDXMLElement *childXMLElement in xpathNodes) {
    [matchingSnapshots addObject:[elementStore objectForKey:[[childXMLElement attributeForName:kXMLIndexPathKey] stringValue]]];
  }

  NSArray *allElements = [[element descendantsMatchingType:XCUIElementTypeAny] allElementsBoundByIndex];
  NSArray *matchingElements = [self filterElements:allElements matchingSnapshots:matchingSnapshots];
  return matchingElements;
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
    [xmlElement addAttribute:[DDXMLNode attributeWithName:@"value" stringValue:snapshot.wdValue]];
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

@end
