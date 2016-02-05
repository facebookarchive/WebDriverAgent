/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCommands.h"

#import <libkern/OSAtomic.h>

#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBXCTElementCache.h"
#import "FBXCTSession.h"
#import "XCTestDriver.h"
#import "XCUIApplication.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+UIAClassMapping.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "XCTHelper.h"

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/element/:id/enabled"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      BOOL isEnabled = element.isWDEnabled;
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, isEnabled ? @YES : @NO);
    }],
    [[FBRoute GET:@"/element/:id/rect"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdRect);
    }],
    [[FBRoute GET:@"/element/:id/size"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
        FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
        XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
        return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdSize);
    }],
    [[FBRoute GET:@"/element/:id/location"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
        FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
        XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
        return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdLocation);
    }],
    [[FBRoute GET:@"/element/:id/location_in_view"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
        FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
        XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
        NSError *error;
        if ([element scrollToVisibleWithError:&error]) {
          return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdLocation);
        } else {
          return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
        }
    }],
    [[FBRoute GET:@"/element/:id/attribute/:name"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      id attributeValue = [element valueForWDAttributeName:request.parameters[@"name"]];
      attributeValue = attributeValue ?: [NSNull null];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, attributeValue);
    }],
    [[FBRoute GET:@"/element/:id/text"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      id text;
      if ([element elementType] == XCUIElementTypeStaticText || [element elementType] == XCUIElementTypeButton) {
        text = [element wdLabel];
      } else {
        text = [element wdValue];
      }
      text = text ?: [NSNull null];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, text);
    }],
    [[FBRoute GET:@"/element/:id/displayed"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      BOOL isVisible = element.isWDVisible;
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, isVisible ? @YES : @NO);
    }],
    [[FBRoute GET:@"/element/:id/name"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
        FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
        NSInteger elementID = [request.parameters[@"id"] integerValue];
        XCUIElement *element = [elementCache elementForIndex:elementID];
        id type = [element wdType];
        return FBResponseDictionaryWithStatus(FBCommandStatusNoError, type);
    }],
    [[FBRoute POST:@"/element/:id/click"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      [element tap];
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute POST:@"/uiaElement/:id/doubleTap"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      [element doubleTap];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/uiaElement/:id/touchAndHold"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      [element pressForDuration:[request.arguments[@"duration"] floatValue]];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/uiaElement/:id/scroll"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];

      // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
      // what ios-driver did and sadly, we must copy them.
      NSString *const name = request.arguments[@"name"];
      if (name) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wdName == %@", name];
        XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
        return [self.class handleScrollElementToVisible:childElement withRequest:request];
      }

      NSString *const direction = request.arguments[@"direction"];
      if (direction) {
        if ([direction isEqualToString:@"up"]) {
          [element scrollUp];
        } else if ([direction isEqualToString:@"down"]) {
          [element scrollDown];
        } else if ([direction isEqualToString:@"left"]) {
          [element scrollLeft];
        } else if ([direction isEqualToString:@"right"]) {
          [element scrollRight];
        }
        return FBResponseDictionaryWithOK();
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
      return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @{});
    }],
    [[FBRoute POST:@"/element/:id/value"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      if (!element.hasKeyboardFocus) {
        [element tap];
      }
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      NSError *error = nil;
      if (![FBXCTElementHelper typeText:textToType error:&error]) {
        return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
      }
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute POST:@"/uiaElement/:id/value"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      XCUIElement *element = [elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      [element adjustToPickerWheelValue:request.arguments[@"value"]];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/element/:id/clear"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [elementCache elementForIndex:elementID];
      if (!element.hasKeyboardFocus) {
        [element tap];
      }
      NSMutableString *textToType = @"".mutableCopy;
      for (NSUInteger i = 0 ; i < [element.value length] ; i++) {
        [textToType appendString:@"\b"];
      }
      NSError *error;
      if (![FBXCTElementHelper typeText:textToType error:&error]) {
        return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
      }
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute POST:@"/uiaTarget/:id/dragfromtoforduration"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTSession *session = (FBXCTSession *)request.session;
      CGVector startPoint = CGVectorMake([request.arguments[@"fromX"] floatValue], [request.arguments[@"fromY"] floatValue]);
      CGVector endPoint = CGVectorMake([request.arguments[@"toX"] floatValue], [request.arguments[@"toY"] floatValue]);
      CGFloat duration = [request.arguments[@"duration"] floatValue];
      XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:session.application normalizedOffset:CGVectorMake(0, 0)];
      XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:endPoint];
      XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:startPoint];
      [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/tap/:id"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTElementCache *elementCache = (FBXCTElementCache *)request.session.elementCache;
      FBXCTSession *session = (FBXCTSession *)request.session;
      CGFloat x = [request.arguments[@"x"] floatValue];
      CGFloat y = [request.arguments[@"y"] floatValue];
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
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/keys"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      NSError *error;
      if (![self.class typeText:textToType error:&error]) {
        return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
      }
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute GET:@"/window/:id/size"] respond:^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBXCTSession *session = (FBXCTSession *)request.session;
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, session.application.wdRect[@"size"]);
    }],
  ];
}

#pragma mark - Helpers

+ (id<FBResponsePayload>)handleScrollElementToVisible:(XCUIElement *)element withRequest:(FBRouteRequest *)request
{
  NSError *error;
  if ([element scrollToVisibleWithError:&error]) {
    return FBResponseDictionaryWithOK();
  } else {
    return FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error.description);
  }
}

@end
