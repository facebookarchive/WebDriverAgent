/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCommands.h"

#import "FBApplication.h"
#import "FBKeyboard.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBErrorBuilder.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "FBWDAMacros.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+Utilities.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "FBElementTypeTransformer.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/element/:id/enabled"] respondWithTarget:self action:@selector(handleGetEnabled:)],
    [[FBRoute GET:@"/element/:id/rect"] respondWithTarget:self action:@selector(handleGetRect:)],
    [[FBRoute GET:@"/element/:id/size"] respondWithTarget:self action:@selector(handleGetSize:)],
    [[FBRoute GET:@"/element/:id/location"] respondWithTarget:self action:@selector(handleGetLocation:)],
    [[FBRoute GET:@"/element/:id/location_in_view"] respondWithTarget:self action:@selector(handleGetLocationInView:)],
    [[FBRoute GET:@"/element/:id/attribute/:name"] respondWithTarget:self action:@selector(handleGetAttribute:)],
    [[FBRoute GET:@"/element/:id/text"] respondWithTarget:self action:@selector(handleGetText:)],
    [[FBRoute GET:@"/element/:id/displayed"] respondWithTarget:self action:@selector(handleGetDisplayed:)],
    [[FBRoute GET:@"/element/:id/accessible"] respondWithTarget:self action:@selector(handleGetAccessible:)],
    [[FBRoute GET:@"/element/:id/name"] respondWithTarget:self action:@selector(handleGetName:)],
    [[FBRoute POST:@"/element/:id/value"] respondWithTarget:self action:@selector(handleGetValue:)],
    [[FBRoute POST:@"/element/:id/click"] respondWithTarget:self action:@selector(handleClick:)],
    [[FBRoute POST:@"/element/:id/clear"] respondWithTarget:self action:@selector(handleClear:)],
    [[FBRoute POST:@"/uiaElement/:id/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTap:)],
    [[FBRoute POST:@"/uiaElement/:id/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHold:)],
    [[FBRoute POST:@"/uiaElement/:id/scroll"] respondWithTarget:self action:@selector(handleScroll:)],
    [[FBRoute POST:@"/uiaElement/:id/value"] respondWithTarget:self action:@selector(handleGetUIAElementValue:)],
    [[FBRoute POST:@"/uiaTarget/:id/dragfromtoforduration"] respondWithTarget:self action:@selector(handleDrag:)],
    [[FBRoute POST:@"/tap/:id"] respondWithTarget:self action:@selector(handleTap:)],
    [[FBRoute POST:@"/keys"] respondWithTarget:self action:@selector(handleKeys:)],
    [[FBRoute GET:@"/window/:id/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetEnabled:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  BOOL isEnabled = element.isWDEnabled;
  return FBResponseWithStatus(FBCommandStatusNoError, isEnabled ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetRect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  return FBResponseWithStatus(FBCommandStatusNoError, element.wdRect);
}

+ (id<FBResponsePayload>)handleGetSize:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  return FBResponseWithStatus(FBCommandStatusNoError, element.wdSize);
}

+ (id<FBResponsePayload>)handleGetLocation:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  return FBResponseWithStatus(FBCommandStatusNoError, element.wdLocation);
}

+ (id<FBResponsePayload>)handleGetLocationInView:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  NSError *error;
  if ([element fb_scrollToVisibleWithError:&error]) {
    return FBResponseWithStatus(FBCommandStatusNoError, element.wdLocation);
  }
  return FBResponseWithError(error);
}

+ (id<FBResponsePayload>)handleGetAttribute:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  id attributeValue = [element fb_valueForWDAttributeName:request.parameters[@"name"]];
  attributeValue = attributeValue ?: [NSNull null];
  return FBResponseWithStatus(FBCommandStatusNoError, attributeValue);
}

+ (id<FBResponsePayload>)handleGetText:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  id text;
  if ([element elementType] == XCUIElementTypeStaticText || [element elementType] == XCUIElementTypeButton) {
    text = [element wdLabel];
  } else {
    text = [element wdValue];
  }
  text = text ?: [NSNull null];
  return FBResponseWithStatus(FBCommandStatusNoError, text);
}

+ (id<FBResponsePayload>)handleGetDisplayed:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  BOOL isVisible = element.isWDVisible;
  return FBResponseWithStatus(FBCommandStatusNoError, isVisible ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetAccessible:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  return FBResponseWithStatus(FBCommandStatusNoError, @(element.isWDAccessible));
}

+ (id<FBResponsePayload>)handleGetName:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  id type = [element wdType];
  return FBResponseWithStatus(FBCommandStatusNoError, type);
}

+ (id<FBResponsePayload>)handleGetValue:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  NSError *error = nil;
  if (!element.hasKeyboardFocus && ![element fb_tapWithError:&error]) {
    return FBResponseWithError(error);
  }
  NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
  if (![FBKeyboard typeText:textToType error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementID(elementID);
}

+ (id<FBResponsePayload>)handleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  NSError *error = nil;
  if (![element fb_tapWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementID(elementID);
}

+ (id<FBResponsePayload>)handleClear:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  NSError *error;
  if (!element.hasKeyboardFocus && ![element fb_tapWithError:&error]) {
    return FBResponseWithError(error);
  }
  NSMutableString *textToType = @"".mutableCopy;
  for (NSUInteger i = 0 ; i < [element.value length] ; i++) {
    [textToType appendString:@"\b"];
  }
  if (![FBKeyboard typeText:textToType error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementID(elementID);
}

+ (id<FBResponsePayload>)handleDoubleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  [element doubleTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
  [element pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScroll:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];

  // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
  // what ios-driver did and sadly, we must copy them.
  NSString *const name = request.arguments[@"name"];
  if (name) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FBStringify(XCUIElement, wdName), name];
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }

  NSString *const direction = request.arguments[@"direction"];
  if (direction) {
    if ([direction isEqualToString:@"up"]) {
      [element fb_scrollUp];
    } else if ([direction isEqualToString:@"down"]) {
      [element fb_scrollDown];
    } else if ([direction isEqualToString:@"left"]) {
      [element fb_scrollLeft];
    } else if ([direction isEqualToString:@"right"]) {
      [element fb_scrollRight];
    }
    return FBResponseWithOK();
  }

  NSString *const predicateString = request.arguments[@"predicateString"];
  if (predicateString) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }

  if (request.arguments[@"toVisible"]) {
    return [self.class handleScrollElementToVisible:element withRequest:request];
  }
  return FBResponseWithErrorFormat(@"Unsupported scroll type");
}

+ (id<FBResponsePayload>)handleGetUIAElementValue:(FBRouteRequest *)request
{
    FBElementCache *elementCache = request.session.elementCache;
    XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
    if (element.elementType != XCUIElementTypePickerWheel) {
        return FBResponseWithErrorFormat(@"Element is not of type %@", [FBElementTypeTransformer shortStringWithElementType:XCUIElementTypePickerWheel]);
    }
    NSString *wheelPickerValue = request.arguments[@"value"];
    
    if (!wheelPickerValue) {
        return FBResponseWithErrorFormat(@"Missing value parameter");
    }
    
    [element adjustToPickerWheelValue:wheelPickerValue];
    return FBResponseWithOK();
    
}

+ (id<FBResponsePayload>)handleDrag:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  CGVector startPoint = CGVectorMake((CGFloat)[request.arguments[@"fromX"] doubleValue], (CGFloat)[request.arguments[@"fromY"] doubleValue]);
  CGVector endPoint = CGVectorMake((CGFloat)[request.arguments[@"toX"] doubleValue], (CGFloat)[request.arguments[@"toY"] doubleValue]);
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:session.application normalizedOffset:CGVectorMake(0, 0)];
  XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:endPoint];
  XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:startPoint];
  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  FBSession *session = request.session;
  CGFloat x = (CGFloat)[request.arguments[@"x"] doubleValue];
  CGFloat y = (CGFloat)[request.arguments[@"y"] doubleValue];
  NSInteger elementID = [request.parameters[@"id"] integerValue];
  XCUIElement *element = [elementCache elementForIndex:elementID];
  if (element != nil) {
    CGRect rect = element.frame;
    x += rect.origin.x;
    y += rect.origin.y;
  }
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:session.application normalizedOffset:CGVectorMake(0, 0)];
  XCUICoordinate *tapCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(x, y)];
  [tapCoordinate tap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleKeys:(FBRouteRequest *)request
{
  NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
  NSError *error;
  if (![FBKeyboard typeText:textToType error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetWindowSize:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  return FBResponseWithStatus(FBCommandStatusNoError, session.application.wdRect[@"size"]);
}


#pragma mark - Helpers

+ (id<FBResponsePayload>)handleScrollElementToVisible:(XCUIElement *)element withRequest:(FBRouteRequest *)request
{
  NSError *error;
  if (!element.exists) {
    return FBResponseWithErrorFormat(@"Can't scroll to element that does not exist");
  }
  if (![element fb_scrollToVisibleWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

@end
