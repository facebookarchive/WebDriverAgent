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
#import "FBMacros.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+AVTyping.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBTyping.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
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
    [[FBRoute GET:@"/element/:uuid/enabled"] respondWithTarget:self action:@selector(handleGetEnabled:)],
    [[FBRoute GET:@"/element/:uuid/rect"] respondWithTarget:self action:@selector(handleGetRect:)],
    [[FBRoute GET:@"/element/:uuid/attribute/:name"] respondWithTarget:self action:@selector(handleGetAttribute:)],
    [[FBRoute GET:@"/element/:uuid/text"] respondWithTarget:self action:@selector(handleGetText:)],
    [[FBRoute GET:@"/element/:uuid/displayed"] respondWithTarget:self action:@selector(handleGetDisplayed:)],
    [[FBRoute GET:@"/element/:uuid/accessible"] respondWithTarget:self action:@selector(handleGetAccessible:)],
    [[FBRoute GET:@"/element/:uuid/accessibilityContainer"] respondWithTarget:self action:@selector(handleGetIsAccessibilityContainer:)],
    [[FBRoute GET:@"/element/:uuid/name"] respondWithTarget:self action:@selector(handleGetName:)],
    [[FBRoute POST:@"/element/:uuid/value"] respondWithTarget:self action:@selector(handleSetValue:)],
    [[FBRoute POST:@"/uiaElement/:uuid/valueSlow"] respondWithTarget:self action:@selector(handleSetSlowValue:)],
    [[FBRoute POST:@"/element/:uuid/click"] respondWithTarget:self action:@selector(handleClick:)],
    [[FBRoute POST:@"/element/:uuid/clear"] respondWithTarget:self action:@selector(handleClear:)],
    [[FBRoute POST:@"/element/:uuid/pinch"] respondWithTarget:self action:@selector(handlePinch:)],
    [[FBRoute POST:@"/uiaElement/:uuid/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTap:)],
    [[FBRoute POST:@"/uiaElement/:uuid/twoFingerTap"] respondWithTarget:self action:@selector(handleTwoFingerTap:)],
    [[FBRoute POST:@"/uiaElement/:uuid/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHold:)],
    [[FBRoute POST:@"/uiaElement/:uuid/scroll"] respondWithTarget:self action:@selector(handleScroll:)],
    [[FBRoute POST:@"/uiaTarget/:uuid/dragfromtoforduration"] respondWithTarget:self action:@selector(handleDrag:)],
    [[FBRoute POST:@"/tap/:uuid"] respondWithTarget:self action:@selector(handleTap:)],
    [[FBRoute POST:@"/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHoldCoordinate:)],
    [[FBRoute POST:@"/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTapCoordinate:)],
    [[FBRoute POST:@"/keys"] respondWithTarget:self action:@selector(handleKeys:)],
    [[FBRoute GET:@"/window/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
    // TODO: This API call should be deprecated and replaced with the one above without the extra :uuid parameter
    [[FBRoute GET:@"/window/:uuid/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetEnabled:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  BOOL isEnabled = element.isWDEnabled;
  return FBResponseWithStatus(FBCommandStatusNoError, isEnabled ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetRect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  return FBResponseWithStatus(FBCommandStatusNoError, element.wdRect);
}

+ (id<FBResponsePayload>)handleGetAttribute:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  id attributeValue = [element fb_valueForWDAttributeName:request.parameters[@"name"]];
  attributeValue = attributeValue ?: [NSNull null];
  return FBResponseWithStatus(FBCommandStatusNoError, attributeValue);
}

+ (id<FBResponsePayload>)handleGetText:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
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
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  BOOL isVisible = element.isWDVisible;
  return FBResponseWithStatus(FBCommandStatusNoError, isVisible ? @YES : @NO);
}

+ (id<FBResponsePayload>)handleGetAccessible:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  return FBResponseWithStatus(FBCommandStatusNoError, @(element.isWDAccessible));
}

+ (id<FBResponsePayload>)handleGetIsAccessibilityContainer:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  return FBResponseWithStatus(FBCommandStatusNoError, @(element.isWDAccessibilityContainer));
}

+ (id<FBResponsePayload>)handleGetName:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  id type = [element wdType];
  return FBResponseWithStatus(FBCommandStatusNoError, type);
}

+ (id<FBResponsePayload>)handleSetValue:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSString *elementUUID = request.parameters[@"uuid"];
  XCUIElement *element = [elementCache elementForUUID:elementUUID];
  id value = request.arguments[@"value"];
  if (!value) {
    return FBResponseWithErrorFormat(@"Missing 'value' parameter");
  }
  NSString *textToType = value;
  if ([value isKindOfClass:[NSArray class]]) {
    textToType = [value componentsJoinedByString:@""];
  }
  if (element.elementType == XCUIElementTypePickerWheel) {
    [element adjustToPickerWheelValue:textToType];
    return FBResponseWithOK();
  }
  if (element.elementType == XCUIElementTypeSlider) {
    CGFloat sliderValue = textToType.floatValue;
    if (sliderValue < 0.0 || sliderValue > 1.0 ) {
      return FBResponseWithErrorFormat(@"Value of slider should be in 0..1 range");
    }
    [element adjustToNormalizedSliderPosition:sliderValue];
    return FBResponseWithOK();
  }
  NSError *error = nil;
  if (![element fb_typeText:textToType error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleSetSlowValue:(FBRouteRequest *)request
{
    FBElementCache *elementCache = request.session.elementCache;
    NSString *elementUUID = request.parameters[@"uuid"];
    XCUIElement *element = [elementCache elementForUUID:elementUUID];
    id value = request.arguments[@"value"];
    if (!value) {
        return FBResponseWithErrorFormat(@"Missing 'value' parameter");
    }
    NSString *textToType = value;
    if ([value isKindOfClass:[NSArray class]]) {
        textToType = [value componentsJoinedByString:@""];
    }
    if (element.elementType == XCUIElementTypePickerWheel) {
        [element adjustToPickerWheelValue:textToType];
        return FBResponseWithOK();
    }
    NSError *error = nil;
    if (![element fb_scrollToVisibleWithError:&error]) {
        return FBResponseWithError(error);
    }
    if (![element av_slowTypeText:textToType error:&error]) {
        return FBResponseWithError(error);
    }
    return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleClick:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSString *elementUUID = request.parameters[@"uuid"];
  XCUIElement *element = [elementCache elementForUUID:elementUUID];
  NSError *error = nil;
  if (![element fb_tapWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleClear:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  NSString *elementUUID = request.parameters[@"uuid"];
  XCUIElement *element = [elementCache elementForUUID:elementUUID];
  NSError *error;
  if (![element fb_clearTextWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithElementUUID(elementUUID);
}

+ (id<FBResponsePayload>)handleDoubleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  [element doubleTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDoubleTapCoordinate:(FBRouteRequest *)request
{
  XCUICoordinate *doubleTapCoordinate = [self.class getGestureCoordinate:request];
  [doubleTapCoordinate doubleTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTwoFingerTap:(FBRouteRequest *)request
{
    FBElementCache *elementCache = request.session.elementCache;
    XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
    [element twoFingerTap];
    return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHold:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  [element pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTouchAndHoldCoordinate:(FBRouteRequest *)request
{
  XCUICoordinate *pressCoordinate = [self.class getGestureCoordinate:request];
  [pressCoordinate pressForDuration:[request.arguments[@"duration"] doubleValue]];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleScroll:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];

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
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
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

+ (id<FBResponsePayload>)handlePinch:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  CGFloat scale = (CGFloat)[request.arguments[@"scale"] doubleValue];
  CGFloat velocity = (CGFloat)[request.arguments[@"velocity"] doubleValue];
  [element pinchWithScale:scale velocity:velocity];
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
  CGRect frame = request.session.application.wdFrame;
  return FBResponseWithStatus(FBCommandStatusNoError, @{
    @"width": @(CGRectGetWidth(frame)),
    @"height": @(CGRectGetHeight(frame)),
  });
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

+ (XCUICoordinate *)getGestureCoordinate:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  CGVector point = CGVectorMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:session.application normalizedOffset:CGVectorMake(0, 0)];
  XCUICoordinate *gestureCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:point];
  return gestureCoordinate;
}

@end
