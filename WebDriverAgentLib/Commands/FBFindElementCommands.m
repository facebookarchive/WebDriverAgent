/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBFindElementCommands.h"

#import "FBAlert.h"
#import "FBElementCache.h"
#import "FBExceptionHandler.h"
#import "FBRouteRequest.h"
#import "FBMacros.h"
#import "FBElementCache.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "XCUIElement+FBFind.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBClassChain.h"

static id<FBResponsePayload> FBNoSuchElementErrorResponseForRequest(FBRouteRequest *request)
{
  NSDictionary *errorDetails = @{
    @"description": @"unable to find an element",
    @"using": request.arguments[@"using"] ?: @"",
    @"value": request.arguments[@"value"] ?: @"",
  };
  return FBResponseWithStatus(FBCommandStatusNoSuchElement, errorDetails);
}

@implementation FBFindElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/element"] respondWithTarget:self action:@selector(handleFindElement:)],
    [[FBRoute POST:@"/elements"] respondWithTarget:self action:@selector(handleFindElements:)],
    [[FBRoute POST:@"/element/:uuid/element"] respondWithTarget:self action:@selector(handleFindSubElement:)],
    [[FBRoute POST:@"/element/:uuid/elements"] respondWithTarget:self action:@selector(handleFindSubElements:)],
    [[FBRoute GET:@"/wda/element/:uuid/getVisibleCells"] respondWithTarget:self action:@selector(handleFindVisibleCells:)],
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
  return FBResponseWithCachedElement(element, request.session.elementCache);
}

+ (id<FBResponsePayload>)handleFindElements:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  NSArray *elements = [self.class elementsUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:session.application
                    shouldReturnAfterFirstMatch:NO];
  return FBResponseWithCachedElements(elements, request.session.elementCache, NO);
}

+ (id<FBResponsePayload>)handleFindVisibleCells:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *collection = [elementCache elementForUUID:request.parameters[@"uuid"]];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == YES", FBStringify(XCUIElement, fb_isVisible)];
  NSArray *elements = [collection.cells matchingPredicate:predicate].allElementsBoundByIndex;
  return FBResponseWithCachedElements(elements, request.session.elementCache, YES);
}

+ (id<FBResponsePayload>)handleFindSubElement:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  XCUIElement *foundElement = [self.class elementUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:element];
  if (!foundElement) {
    return FBNoSuchElementErrorResponseForRequest(request);
  }
  return FBResponseWithCachedElement(foundElement, request.session.elementCache);
}

+ (id<FBResponsePayload>)handleFindSubElements:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  NSArray *foundElements = [self.class elementsUsing:request.arguments[@"using"] withValue:request.arguments[@"value"] under:element
                         shouldReturnAfterFirstMatch:NO];

  return FBResponseWithCachedElements(foundElements, request.session.elementCache, NO);
}


#pragma mark - Helpers

+ (XCUIElement *)elementUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element
{
  return [[self elementsUsing:usingText withValue:value under:element shouldReturnAfterFirstMatch:YES] firstObject];
}

+ (NSArray *)elementsUsing:(NSString *)usingText withValue:(NSString *)value under:(XCUIElement *)element shouldReturnAfterFirstMatch:(BOOL)shouldReturnAfterFirstMatch
{
  NSArray *elements;
  const BOOL partialSearch = [usingText isEqualToString:@"partial link text"];
  const BOOL isSearchByIdentifier = ([usingText isEqualToString:@"name"] || [usingText isEqualToString:@"id"] || [usingText isEqualToString:@"accessibility id"]);
  if (partialSearch || [usingText isEqualToString:@"link text"]) {
    NSArray *components = [value componentsSeparatedByString:@"="];
    NSString *propertyValue = components.lastObject;
    NSString *propertyName = (components.count < 2 ? @"name" : components.firstObject);
    elements = [element fb_descendantsMatchingProperty:propertyName value:propertyValue partialSearch:partialSearch];
  } else if ([usingText isEqualToString:@"class name"]) {
    elements = [element fb_descendantsMatchingClassName:value shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"class chain"]) {
    elements = [element fb_descendantsMatchingClassChain:value shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"xpath"]) {
    elements = [element fb_descendantsMatchingXPathQuery:value shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if ([usingText isEqualToString:@"predicate string"]) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:value];
    elements = [element fb_descendantsMatchingPredicate:predicate shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else if (isSearchByIdentifier) {
    elements = [element fb_descendantsMatchingIdentifier:value shouldReturnAfterFirstMatch:shouldReturnAfterFirstMatch];
  } else {
    [[NSException exceptionWithName:FBElementAttributeUnknownException reason:[NSString stringWithFormat:@"Invalid locator requested: %@", usingText] userInfo:nil] raise];
  }
  return [[FBAlert alertWithApplication:element.application] filterObstructedElements:elements];
}

@end
