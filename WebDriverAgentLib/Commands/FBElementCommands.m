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
#import "FBPredicate.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBErrorBuilder.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBRuntimeUtils.h"
#import "NSPredicate+FBFormat.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBPickerWheel.h"
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
    [[FBRoute GET:@"/window/size"] respondWithTarget:self action:@selector(handleGetWindowSize:)],
    [[FBRoute GET:@"/element/:uuid/enabled"] respondWithTarget:self action:@selector(handleGetEnabled:)],
    [[FBRoute GET:@"/element/:uuid/rect"] respondWithTarget:self action:@selector(handleGetRect:)],
    [[FBRoute GET:@"/element/:uuid/attribute/:name"] respondWithTarget:self action:@selector(handleGetAttribute:)],
    [[FBRoute GET:@"/element/:uuid/text"] respondWithTarget:self action:@selector(handleGetText:)],
    [[FBRoute GET:@"/element/:uuid/displayed"] respondWithTarget:self action:@selector(handleGetDisplayed:)],
    [[FBRoute GET:@"/element/:uuid/name"] respondWithTarget:self action:@selector(handleGetName:)],
    [[FBRoute POST:@"/element/:uuid/value"] respondWithTarget:self action:@selector(handleSetValue:)],
    [[FBRoute POST:@"/element/:uuid/click"] respondWithTarget:self action:@selector(handleClick:)],
    [[FBRoute POST:@"/element/:uuid/clear"] respondWithTarget:self action:@selector(handleClear:)],
    [[FBRoute GET:@"/element/:uuid/screenshot"] respondWithTarget:self action:@selector(handleElementScreenshot:)],
    [[FBRoute GET:@"/wda/element/:uuid/accessible"] respondWithTarget:self action:@selector(handleGetAccessible:)],
    [[FBRoute GET:@"/wda/element/:uuid/accessibilityContainer"] respondWithTarget:self action:@selector(handleGetIsAccessibilityContainer:)],
    [[FBRoute POST:@"/wda/element/:uuid/swipe"] respondWithTarget:self action:@selector(handleSwipe:)],
    [[FBRoute POST:@"/wda/element/:uuid/pinch"] respondWithTarget:self action:@selector(handlePinch:)],
    [[FBRoute POST:@"/wda/element/:uuid/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTap:)],
    [[FBRoute POST:@"/wda/element/:uuid/twoFingerTap"] respondWithTarget:self action:@selector(handleTwoFingerTap:)],
    [[FBRoute POST:@"/wda/element/:uuid/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHold:)],
    [[FBRoute POST:@"/wda/element/:uuid/scroll"] respondWithTarget:self action:@selector(handleScroll:)],
    [[FBRoute POST:@"/wda/element/:uuid/dragfromtoforduration"] respondWithTarget:self action:@selector(handleDrag:)],
    [[FBRoute POST:@"/wda/dragfromtoforduration"] respondWithTarget:self action:@selector(handleDragCoordinate:)],
    [[FBRoute POST:@"/wda/tap/:uuid"] respondWithTarget:self action:@selector(handleTap:)],
    [[FBRoute POST:@"/wda/touchAndHold"] respondWithTarget:self action:@selector(handleTouchAndHoldCoordinate:)],
    [[FBRoute POST:@"/wda/doubleTap"] respondWithTarget:self action:@selector(handleDoubleTapCoordinate:)],
    [[FBRoute POST:@"/wda/keys"] respondWithTarget:self action:@selector(handleKeys:)],
    [[FBRoute POST:@"/wda/pickerwheel/:uuid/select"] respondWithTarget:self action:@selector(handleWheelSelect:)]
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
  id text = FBFirstNonEmptyValue(element.wdValue, element.wdLabel);
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
  CGPoint doubleTapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *doubleTapCoordinate = [self.class gestureCoordinateWithCoordinate:doubleTapPoint application:request.session.activeApplication shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
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
  CGPoint touchPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *pressCoordinate = [self.class gestureCoordinateWithCoordinate:touchPoint application:request.session.activeApplication shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
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
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:name] allElementsBoundByAccessibilityElement] lastObject];
    if (!childElement) {
      return FBResponseWithErrorFormat(@"'%@' identifier didn't match any elements", name);
    }
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }

  NSString *const direction = request.arguments[@"direction"];
  if (direction) {
    NSString *const distanceString = request.arguments[@"distance"] ?: @"1.0";
    CGFloat distance = (CGFloat)distanceString.doubleValue;
    if ([direction isEqualToString:@"up"]) {
      [element fb_scrollUpByNormalizedDistance:distance];
    } else if ([direction isEqualToString:@"down"]) {
      [element fb_scrollDownByNormalizedDistance:distance];
    } else if ([direction isEqualToString:@"left"]) {
      [element fb_scrollLeftByNormalizedDistance:distance];
    } else if ([direction isEqualToString:@"right"]) {
      [element fb_scrollRightByNormalizedDistance:distance];
    }
    return FBResponseWithOK();
  }

  NSString *const predicateString = request.arguments[@"predicateString"];
  if (predicateString) {
    NSPredicate *formattedPredicate = [NSPredicate fb_formatSearchPredicate:[FBPredicate predicateWithFormat:predicateString]];
    XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:formattedPredicate] allElementsBoundByAccessibilityElement] lastObject];
    if (!childElement) {
      return FBResponseWithErrorFormat(@"'%@' predicate didn't match any elements", predicateString);
    }
    return [self.class handleScrollElementToVisible:childElement withRequest:request];
  }

  if (request.arguments[@"toVisible"]) {
    return [self.class handleScrollElementToVisible:element withRequest:request];
  }
  return FBResponseWithErrorFormat(@"Unsupported scroll type");
}

+ (id<FBResponsePayload>)handleDragCoordinate:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  CGPoint startPoint = CGPointMake((CGFloat)[request.arguments[@"fromX"] doubleValue], (CGFloat)[request.arguments[@"fromY"] doubleValue]);
  CGPoint endPoint = CGPointMake((CGFloat)[request.arguments[@"toX"] doubleValue], (CGFloat)[request.arguments[@"toY"] doubleValue]);
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  XCUICoordinate *endCoordinate = [self.class gestureCoordinateWithCoordinate:endPoint application:session.activeApplication shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  XCUICoordinate *startCoordinate = [self.class gestureCoordinateWithCoordinate:startPoint application:session.activeApplication shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDrag:(FBRouteRequest *)request
{
  FBSession *session = request.session;
  FBElementCache *elementCache = session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  CGPoint startPoint = CGPointMake((CGFloat)(element.frame.origin.x + [request.arguments[@"fromX"] doubleValue]), (CGFloat)(element.frame.origin.y + [request.arguments[@"fromY"] doubleValue]));
  CGPoint endPoint = CGPointMake((CGFloat)(element.frame.origin.x + [request.arguments[@"toX"] doubleValue]), (CGFloat)(element.frame.origin.y + [request.arguments[@"toY"] doubleValue]));
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  BOOL shouldApplyOrientationWorkaround = isSDKVersionGreaterThanOrEqualTo(@"10.0") && isSDKVersionLessThan(@"11.0");
  XCUICoordinate *endCoordinate = [self.class gestureCoordinateWithCoordinate:endPoint application:session.activeApplication shouldApplyOrientationWorkaround:shouldApplyOrientationWorkaround];
  XCUICoordinate *startCoordinate = [self.class gestureCoordinateWithCoordinate:startPoint application:session.activeApplication shouldApplyOrientationWorkaround:shouldApplyOrientationWorkaround];
  [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleSwipe:(FBRouteRequest *)request
{
    FBElementCache *elementCache = request.session.elementCache;
    XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
    NSString *const direction = request.arguments[@"direction"];
    if (!direction) {
        return FBResponseWithErrorFormat(@"Missing 'direction' parameter");
    }
    if ([direction isEqualToString:@"up"]) {
        [element swipeUp];
    } else if ([direction isEqualToString:@"down"]) {
        [element swipeDown];
    } else if ([direction isEqualToString:@"left"]) {
        [element swipeLeft];
    } else if ([direction isEqualToString:@"right"]) {
        [element swipeRight];
    } else {
      return FBResponseWithErrorFormat(@"Unsupported swipe type");
    }
    return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTap:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  if (nil == element) {
    XCUICoordinate *tapCoordinate = [self.class gestureCoordinateWithCoordinate:tapPoint application:request.session.activeApplication shouldApplyOrientationWorkaround:isSDKVersionLessThan(@"11.0")];
    [tapCoordinate tap];
  } else {
    NSError *error;
    if (![element fb_tapCoordinate:tapPoint error:&error]) {
      return FBResponseWithError(error);
    }
  }
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
  CGRect frame = request.session.activeApplication.wdFrame;
  CGSize screenSize = FBAdjustDimensionsForApplication(frame.size, request.session.activeApplication.interfaceOrientation);
  return FBResponseWithStatus(FBCommandStatusNoError, @{
    @"width": @(screenSize.width),
    @"height": @(screenSize.height),
  });
}

+ (id<FBResponsePayload>)handleElementScreenshot:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  NSError *error;
  NSData *screenshotData = [element fb_screenshotWithError:&error];
  if (nil == screenshotData) {
    return FBResponseWithError(error);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

static const CGFloat DEFAULT_OFFSET = (CGFloat)0.2;

+ (id<FBResponsePayload>)handleWheelSelect:(FBRouteRequest *)request
{
  FBElementCache *elementCache = request.session.elementCache;
  XCUIElement *element = [elementCache elementForUUID:request.parameters[@"uuid"]];
  if (element.elementType != XCUIElementTypePickerWheel) {
    return FBResponseWithErrorFormat(@"The element is expected to be a valid Picker Wheel control. '%@' was given instead", element.wdType);
  }
  NSString* order = [request.arguments[@"order"] lowercaseString];
  CGFloat offset = DEFAULT_OFFSET;
  if (request.arguments[@"offset"]) {
    offset = (CGFloat)[request.arguments[@"offset"] doubleValue];
    if (offset <= 0.0 || offset > 0.5) {
      return FBResponseWithErrorFormat(@"'offset' value is expected to be in range (0.0, 0.5]. '%@' was given instead", request.arguments[@"offset"]);
    }
  }
  BOOL isSuccessful = false;
  NSError *error;
  if ([order isEqualToString:@"next"]) {
    isSuccessful = [element fb_selectNextOptionWithOffset:offset error:&error];
  } else if ([order isEqualToString:@"previous"]) {
    isSuccessful = [element fb_selectPreviousOptionWithOffset:offset error:&error];
  } else {
    return FBResponseWithErrorFormat(@"Only 'previous' and 'next' order values are supported. '%@' was given instead", request.arguments[@"order"]);
  }
  if (!isSuccessful) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
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

/**
 Returns gesture coordinate for the application based on absolute coordinate

 @param coordinate absolute screen coordinates
 @param application the instance of current application under test
 @shouldApplyOrientationWorkaround whether to apply orientation workaround. This is to
 handle XCTest bug where it does not translate screen coordinates for elements if
 screen orientation is different from the default one (which is portrait).
 Different iOS version have different behavior, for example iOS 9.3 returns correct
 coordinates for elements in landscape, but iOS 10.0+ returns inverted coordinates as if
 the current screen orientation would be portrait.
 @return translated gesture coordinates ready to be passed to XCUICoordinate methods
 */
+ (XCUICoordinate *)gestureCoordinateWithCoordinate:(CGPoint)coordinate application:(XCUIApplication *)application shouldApplyOrientationWorkaround:(BOOL)shouldApplyOrientationWorkaround
{
  CGPoint point = coordinate;
  if (shouldApplyOrientationWorkaround) {
    point = FBInvertPointForApplication(coordinate, application.frame.size, application.interfaceOrientation);
  }
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:application normalizedOffset:CGVectorMake(0, 0)];
  return [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(point.x, point.y)];
}

@end
