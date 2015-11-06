/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCommands.h"

#import <CoreImage/CoreImage.h>

#import "FBElementCache.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
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

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"GET@/session/:sessionID/element/:id/enabled" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      BOOL isEnabled = element.isEnabled;
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, isEnabled ? @YES : @NO));
    },
    @"GET@/session/:sessionID/element/:id/rect" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [element wdRect]));
    },
    @"GET@/session/:sessionID/element/:id/attribute/:name" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      id attributeValue = [element valueForWDAttributeName:request.parameters[@"name"]];
      attributeValue = attributeValue ?: [NSNull null];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, attributeValue));
    },
    @"GET@/session/:sessionID/element/:id/text" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
        NSInteger elementID = [request.parameters[@"id"] integerValue];
        XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
        id text;
        if ([element elementType] == XCUIElementTypeStaticText) {
          text = [element label];
        } else {
          text = [element value];
        }
        text = text ?: [NSNull null];
        completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, text));
    },
    @"GET@/session/:sessionID/element/:id/displayed" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      BOOL isVisible = element.isFBVisible;
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, isVisible ? @YES : @NO));
    },
    @"POST@/session/:sessionID/element/:id/click" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      [element tap];
      completionHandler(FBResponseDictionaryWithElementID(elementID));
    },
    @"POST@/session/:sessionID/uiaElement/:id/doubleTap": ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      [element doubleTap];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/uiaElement/:id/touchAndHold" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      [element pressForDuration:[request.arguments[@"duration"] floatValue]];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/uiaElement/:id/scroll" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];

      // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
      // what ios-driver did and sadly, we must copy them.
      NSString *const name = request.arguments[@"name"];
      if (name) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"wdName == %@", name];
        XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
        [self.class handleScrollElementToVisible:childElement withRequest:request completionHandler:completionHandler];
        return;
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
        completionHandler(FBResponseDictionaryWithOK());
        return;
      }

      NSString *const predicateString = request.arguments[@"predicateString"];
      if (predicateString) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
        XCUIElement *childElement = [[[[element descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate] allElementsBoundByIndex] lastObject];
        [self.class handleScrollElementToVisible:childElement withRequest:request completionHandler:completionHandler];
        return;
      }

      if (request.arguments[@"toVisible"]) {
        [self.class handleScrollElementToVisible:element withRequest:request completionHandler:completionHandler];
        return;
      }
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @{}));
    },
    @"POST@/session/:sessionID/element/:id/value" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      if (!element.hasKeyboardFocus) {
        [element tap];
      }
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [element typeText:textToType];
      completionHandler(FBResponseDictionaryWithElementID(elementID));
    },
    @"POST@/session/:sessionID/uiaElement/:id/value": ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      XCUIElement *element = [request.session.elementCache elementForIndex:[request.parameters[@"id"] integerValue]];
      [element adjustToPickerWheelValue:request.arguments[@"value"]];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/element/:id/clear" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      if (!element.hasKeyboardFocus) {
        [element tap];
      }
      NSMutableString *textToType = @"".mutableCopy;
      for (NSUInteger i = 0 ; i < [element.value length] ; i++) {
        [textToType appendString:@"\b"];
      }
      [element typeText:textToType];
      completionHandler(FBResponseDictionaryWithElementID(elementID));
    },
    @"POST@/session/:sessionID/uiaTarget/:id/dragfromtoforduration": ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      CGVector startPoint = CGVectorMake([request.arguments[@"fromX"] floatValue], [request.arguments[@"fromY"] floatValue]);
      CGVector endPoint = CGVectorMake([request.arguments[@"toX"] floatValue], [request.arguments[@"toY"] floatValue]);
      CGFloat duration = [request.arguments[@"duration"] floatValue];
      XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:request.session.application normalizedOffset:CGVectorMake(0, 0)];
      XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:endPoint];
      XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:startPoint];
      [startCoordinate pressForDuration:duration thenDragToCoordinate:endCoordinate];
    },
    @"POST@/session/:sessionID/tap/:id" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      CGFloat x = [request.arguments[@"x"] floatValue];
      CGFloat y = [request.arguments[@"y"] floatValue];
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      XCUIElement *element = [request.session.elementCache elementForIndex:elementID];
      if (element != nil) {
        CGRect rect = element.frame;
        x += rect.origin.x;
        y += rect.origin.y;
      }
      XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:request.session.application normalizedOffset:CGVectorMake(0, 0)];
      XCUICoordinate *tapCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(x, y)];
      [tapCoordinate tap];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/keys" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [[XCTestDriver sharedTestDriver].managerProxy _XCT_sendString:textToType completion:^(NSError *error){
        if (error) {
            completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, error));
          return;
        }
        completionHandler(FBResponseDictionaryWithOK());
      }];
    },
    @"GET@/session/:sessionID/window/:id/size" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSDictionary *rect = [request.session.application valueForWDAttributeName:@"rect"];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, rect[@"size"]));
    },
  };
}


#pragma mark - Helpers

+ (void)handleScrollElementToVisible:(XCUIElement *)element withRequest:(FBRouteRequest *)request completionHandler:(FBRouteResponseCompletion)completionHandler
{
  [element resolve];
  [element scrollToVisible];
  [element resolve];
  if (!element.isFBVisible) {
    completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusUnhandled, @{}));
    return;
  }
  completionHandler(FBResponseDictionaryWithOK());
}

@end
