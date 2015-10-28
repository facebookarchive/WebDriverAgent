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

+ (NSArray *)routes
{
  return @[
    [[FBRoute POST:@"/session/:sessionID/tap/:reference"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      CGFloat x = [request.arguments[@"x"] floatValue];
      CGFloat y = [request.arguments[@"y"] floatValue];
      NSInteger elementID = [request.parameters[@"reference"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      if (element != nil) {
        CGRect rect = [[element valueForKey:@"rect"] CGRectValue];
        x += rect.origin.x;
        y += rect.origin.y;
      }
      [[UIATarget localTarget] tap:@{ @"x": @(x), @"y": @(y) }];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/element/:id/click"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      [element tap];
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute GET:@"/session/:sessionID/element/:id/displayed"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      BOOL isVisible = [[element isVisible] boolValue];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, isVisible ? @"1" : @"0");
    }],
    [[FBRoute GET:@"/session/:sessionID/element/:id/enabled"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      BOOL isEnabled = [[element isEnabled] boolValue];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, isEnabled ? @"1" : @"0");
    }],
    [[FBRoute GET:@"/session/:sessionID/element/:id/text"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      id text = [element value];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, text);
    }],
    [[FBRoute POST:@"/session/:sessionID/element/:id/clear"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.arguments[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];

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

      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute POST:@"/session/:sessionID/element/:id/value"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.arguments[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      if (![[element hasKeyboardFocus] boolValue]) {
        [element tap];
      }
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [self.class typeText:textToType];
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute POST:@"/session/:sessionID/keys"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [self.class typeText:textToType];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/uiaElement/:elementID/doubleTap"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      UIAElement *element = [request.elementCache elementForIndex:[request.parameters[@"elementID"] integerValue]];
      [element doubleTap];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/uiaElement/:id/touchAndHold"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      UIAElement *element = [request.elementCache elementForIndex:[request.arguments[@"element"] integerValue]];
      [element touchAndHold:@([request.arguments[@"duration"] floatValue])];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/uiaTarget/:id/dragfromtoforduration"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [[UIATarget localTarget] dragFrom:@{ @"x": request.arguments[@"fromX"], @"y": request.arguments[@"fromY"] } to:@{ @"x": request.arguments[@"toX"], @"y": request.arguments[@"toY"] } forDuration:request.arguments[@"duration"]];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute GET:@"/session/:sessionID/element/:elementID/rect"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      UIAElement *element = [request.elementCache elementForIndex:[request.parameters[@"elementID"] integerValue]];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class attribute:@"rect" onElement:element]);
    }],
    [[FBRoute GET:@"/session/:sessionID/element/:id/attribute/:name"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      UIAElement *element = [request.elementCache elementForIndex:elementID];
      id attributeValue = [self.class attribute:request.parameters[@"name"] onElement:element];
      attributeValue = attributeValue ?: [NSNull null];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, attributeValue);
    }],
    [[FBRoute GET:@"/session/:sessionID/window/:windowHandle/size"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [self.class attribute:@"rect" onElement:[UIATarget localTarget]][@"size"]);
    }],
    [[FBRoute POST:@"/session/:sessionID/uiaElement/:element/scroll"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      UIAElement *element = [request.elementCache elementForIndex:[request.arguments[@"element"] integerValue]];

      // Using presence of arguments as a way to convey control flow seems like a pretty bad idea but it's
      // what ios-driver did and sadly, we must copy them.
      if (request.arguments[@"name"]) {
        [element scrollToElementWithName:request.arguments[@"name"]];
      } else if (request.arguments[@"direction"]) {
        NSString *direction = request.arguments[@"direction"];
        if ([direction isEqualToString:@"up"]) {
          [element scrollUp];
        } else if ([direction isEqualToString:@"down"]) {
          [element scrollDown];
        } else if ([direction isEqualToString:@"left"]) {
          [element scrollLeft];
        } else if ([direction isEqualToString:@"right"]) {
          [element scrollRight];
        }
      } else if (request.arguments[@"predicateString"]) {
        [element scrollToElementWithPredicate:request.arguments[@"predicateString"]];
      } else if (request.arguments[@"toVisible"]) {
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
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/session/:sessionID/uiaElement/:elementID/value"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      UIAPickerWheel *element = (UIAPickerWheel *)[request.elementCache elementForIndex:[request.arguments[@"element"] integerValue]];
      [element selectValue:request.arguments[@"value"]];
      return FBResponseDictionaryWithOK();
    }],
  ];
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
