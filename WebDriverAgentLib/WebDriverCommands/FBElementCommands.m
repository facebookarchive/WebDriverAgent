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
#import "FBWDAConstants.h"
#import "FBWDAMacros.h"
#import "UIAApplication.h"
#import "UIACollectionView.h"
#import "UIAKeyboard.h"
#import "UIAPickerWheel.h"
#import "UIATarget.h"

@interface FBElementCommands ()
@end

@implementation FBElementCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"POST@/session/:sessionID/tap/:reference" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      CGFloat x = [params.arguments[@"x"] floatValue];
      CGFloat y = [params.arguments[@"y"] floatValue];
      [[UIATarget localTarget] tap:@{ @"x": @(x), @"y": @(y) }];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/element/:id/click" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [params.parameters[@"id"] integerValue];
      UIAElement *element = [params.elementCache elementForIndex:elementID];
      [element tap];
      completionHandler(FBResponseDictionaryWithElementID(elementID));
    },
    @"GET@/session/:sessionID/element/:id/displayed" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [params.parameters[@"id"] integerValue];
      UIAElement *element = [params.elementCache elementForIndex:elementID];
      BOOL isVisible = [[element isVisible] boolValue];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, isVisible ? @"1" : @"0"));
    },
    @"GET@/session/:sessionID/element/:id/enabled" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [params.parameters[@"id"] integerValue];
      UIAElement *element = [params.elementCache elementForIndex:elementID];
      BOOL isEnabled = [[element isEnabled] boolValue];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, isEnabled ? @"1" : @"0"));
    },
    @"POST@/session/:sessionID/element/:id/clear" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [params.arguments[@"id"] integerValue];
      UIAElement *element = [params.elementCache elementForIndex:elementID];

      // TODO(t8077426): This is a terrible workaround to get tests in t8036026 passing.
      // It's possible that the client has allready called tap on the element.
      // If this is the case then -[UIElement setValue:] will still call 'tap'.
      // In thise case an exception will be thrown.
      if (FBWDAConstants.isIOS9OrGreater) {
        @try {
          [element setValue:@""];
        }
        @catch (NSException *exception) {
        }
      } else {
        [element setValue:@""];
      }

      completionHandler(FBResponseDictionaryWithElementID(elementID));
    },
    @"POST@/session/:sessionID/element/:id/value" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [params.arguments[@"id"] integerValue];
      UIAElement *element = [params.elementCache elementForIndex:elementID];
      if (![[element hasKeyboardFocus] boolValue]) {
        [element tap];
      }
      NSString *textToType = [params.arguments[@"value"] componentsJoinedByString:@""];
      [self.class typeText:textToType];
      completionHandler(FBResponseDictionaryWithElementID(elementID));
    },
    @"POST@/session/:sessionID/keys" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [self.class typeText:textToType];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/uiaElement/:elementID/doubleTap": ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      UIAElement *element = [params.elementCache elementForIndex:[params.parameters[@"elementID"] integerValue]];
      [element doubleTap];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/uiaElement/:id/touchAndHold" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      UIAElement *element = [params.elementCache elementForIndex:[params.arguments[@"element"] integerValue]];
      [element touchAndHold:@([params.arguments[@"duration"] floatValue])];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/uiaTarget/:id/dragfromtoforduration": ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      [[UIATarget localTarget] dragFrom:@{ @"x": params.arguments[@"fromX"], @"y": params.arguments[@"fromY"] } to:@{ @"x": params.arguments[@"toX"], @"y": params.arguments[@"toY"] } forDuration:params.arguments[@"duration"]];
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"GET@/session/:sessionID/element/:elementID/rect" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      UIAElement *element = [params.elementCache elementForIndex:[params.parameters[@"elementID"] integerValue]];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class attribute:@"rect" onElement:element]));
    },
    @"GET@/session/:sessionID/element/:id/attribute/:name" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      NSInteger elementID = [params.parameters[@"id"] integerValue];
      UIAElement *element = [params.elementCache elementForIndex:elementID];
      id attributeValue = [self.class attribute:params.parameters[@"name"] onElement:element];
      attributeValue = attributeValue ?: [NSNull null];
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, attributeValue));
    },
    @"GET@/session/:sessionID/window/:windowHandle/size" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class attribute:@"rect" onElement:[UIATarget localTarget]][@"size"]));
    },
    @"POST@/session/:sessionID/uiaElement/:element/scroll" : ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      UIAElement *element = [params.elementCache elementForIndex:[params.arguments[@"element"] integerValue]];

      // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
      // what ios-driver did and sadly, we must copy them.
      if (params.arguments[@"name"]) {
        [element scrollToElementWithName:params.arguments[@"name"]];
      } else if (params.arguments[@"direction"]) {
        NSString *direction = params.arguments[@"direction"];
        if ([direction isEqualToString:@"up"]) {
          [element scrollUp];
        } else if ([direction isEqualToString:@"down"]) {
          [element scrollDown];
        } else if ([direction isEqualToString:@"left"]) {
          [element scrollLeft];
        } else if ([direction isEqualToString:@"right"]) {
          [element scrollRight];
        }
      } else if (params.arguments[@"predicateString"]) {
        [element scrollToElementWithPredicate:params.arguments[@"predicateString"]];
      } else if (params.arguments[@"toVisible"]) {
        id rect;
        int counter = 0;
        // Calling scrollToVisible sometimes scrolls element in a way that it is still invisible.
        // This will try 10 times to scroll element till stable rect is reached.
        while (![[element rect] isEqual:rect]) {
          rect = [element rect];
          [element scrollToVisible];
          if (counter > 10) {
            break;
          }
          counter++;
        }
      }
      completionHandler(FBResponseDictionaryWithOK());
    },
    @"POST@/session/:sessionID/uiaElement/:elementID/value": ^(FBRouteRequest *params, FBRouteResponseCompletion completionHandler) {
      UIAPickerWheel *element = (UIAPickerWheel *)[params.elementCache elementForIndex:[params.arguments[@"element"] integerValue]];
      [element selectValue:params.arguments[@"value"]];
      completionHandler(FBResponseDictionaryWithOK());
    },
  };
}


#pragma mark - Helpers

+ (void)typeText:(NSString *)text
{
  UIAKeyboard *keyboard = [[[UIATarget localTarget] frontMostApp] keyboard];
  [keyboard setInterKeyDelay:0.25];
  [keyboard typeString:text];
}

+ (id)attribute:(NSString *)name onElement:(UIAElement *)element
{
  FBWDAAssertMainThread();

  if ([name isEqualToString:@"type"]) {
    return [element className];
  }
  [UIAElement pushPatience:0];
  id value = [element valueForKey:name];
  [UIAElement popPatience];

  if ([name isEqualToString:@"rect"]) {
    CGRect rect = [value CGRectValue];
    return @{
             @"origin": @{
                 @"x": @(rect.origin.x),
                 @"y": @(rect.origin.y),
                 },
             @"size": @{
                 @"width": @(rect.size.width),
                 @"height": @(rect.size.height),
                 },
             };
  }

  return value;
}

@end
