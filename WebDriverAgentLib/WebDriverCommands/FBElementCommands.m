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

#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBUIAElementCache.h"
#import "FBWDAConstants.h"
#import "FBWDAMacros.h"
#import "UIAApplication.h"
#import "UIACollectionView.h"
#import "UIAElement+WebDriverAttributes.h"
#import "UIAHardwareKeyboard.h"
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
    [[FBRoute POST:@"/tap/:reference"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      CGFloat x = [request.arguments[@"x"] floatValue];
      CGFloat y = [request.arguments[@"y"] floatValue];
      NSInteger elementID = [request.parameters[@"reference"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];
      if (element != nil) {
        CGRect rect = element.wdFrame;
        x += rect.origin.x;
        y += rect.origin.y;
      }
      [[UIATarget localTarget] tap:@{ @"x": @(x), @"y": @(y) }];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/element/:id/click"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];
      [element tap];
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute GET:@"/element/:id/displayed"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.isWDVisible ? @YES : @NO);
    }],
    [[FBRoute GET:@"/element/:id/enabled"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.isWDEnabled ? @YES : @NO);
    }],
    [[FBRoute GET:@"/element/:id/text"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdValue);
    }],
    [[FBRoute POST:@"/element/:id/clear"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];

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
    [[FBRoute POST:@"/element/:id/value"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:elementID];
      if (![element.hasKeyboardFocus boolValue]) {
        [element tap];
      }
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [self.class typeText:textToType];
      return FBResponseDictionaryWithElementID(elementID);
    }],
    [[FBRoute POST:@"/keys"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      NSString *textToType = [request.arguments[@"value"] componentsJoinedByString:@""];
      [self.class typeText:textToType];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/uiaElement/:elementID/doubleTap"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:[request.parameters[@"elementID"] integerValue]];
      [element doubleTap];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/uiaElement/:id/touchAndHold"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:[request.arguments[@"element"] integerValue]];
      [element touchAndHold:@([request.arguments[@"duration"] floatValue])];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute POST:@"/uiaTarget/:id/dragfromtoforduration"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      [[UIATarget localTarget] dragFrom:@{ @"x": request.arguments[@"fromX"], @"y": request.arguments[@"fromY"] } to:@{ @"x": request.arguments[@"toX"], @"y": request.arguments[@"toY"] } forDuration:request.arguments[@"duration"]];
      return FBResponseDictionaryWithOK();
    }],
    [[FBRoute GET:@"/element/:elementID/rect"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:[request.parameters[@"elementID"] integerValue]];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, element.wdRect);
    }],
    [[FBRoute GET:@"/element/:id/attribute/:name"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      NSInteger elementID = [request.parameters[@"id"] integerValue];
      UIAElement *element = [elementCache elementForIndex:elementID];
      id attributeValue = [element valueForWDAttributeName:request.parameters[@"name"]];
      attributeValue = attributeValue ?: [NSNull null];
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, attributeValue);
    }],
    [[FBRoute GET:@"/window/:windowHandle/size"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseDictionaryWithStatus(FBCommandStatusNoError, [UIATarget localTarget].wdRect[@"size"]);
    }],
    [[FBRoute POST:@"/uiaElement/:element/scroll"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      FBUIAElementCache *elementCache = (FBUIAElementCache *)request.session.elementCache;
      UIAElement *element = [elementCache elementForIndex:[request.arguments[@"element"] integerValue]];

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
    [[FBRoute POST:@"/uiaElement/:elementID/value"] respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      UIAPickerWheel *wheelElement = (UIAPickerWheel *)[request.session.elementCache elementForIndex:[request.arguments[@"element"] integerValue]];
      [wheelElement selectValue:request.arguments[@"value"]];
      return FBResponseDictionaryWithOK();
    }],
  ];
}


#pragma mark - Helpers

+ (void)typeText:(NSString *)text
{
  // Our hardware keyboard hack breaks when we try to hit backspace, so let's revert to the old strategy in those cases.
  // Like all terrible code, I claim this will be gone completely in a couple months when we switch drivers.
  if ([text containsString:@"\b"]) {
    UIAKeyboard *keyboard = [[[UIATarget localTarget] frontMostApp] keyboard];
    [keyboard setInterKeyDelay:0.25];
    [keyboard typeString:text];
    return;
  }

  for (NSInteger i = 0; i < [text length]; i++) {
    NSString *characterString = [text substringWithRange:NSMakeRange(i, 1)];
    NSDictionary *shift =
    @{
      @"!": @"1",
      @"@": @"2",
      @"#": @"3",
      @"$": @"4",
      @"%": @"5",
      @"^": @"6",
      @"&": @"7",
      @"*": @"8",
      @"(": @"9",
      @")": @"0",
      @"_": @"-",
      @"?": @"/",
      @"+": @"=",
      @":": @";",
      @"~": @"`",
      @"{": @"[",
      @"}": @"]",
      @"\"": @"'",
      @"<": @",",
      @">": @".",
      @"~": @"`",
      @"|": @"\\",
      };
    NSArray *specialKeyCodes = @[ @"\n", @"", @"\b", @"\t", @" ", @"-", @"=", @"[", @"]", @"\\", @"\\", @";", @"'", @"`", @",", @".", @"/" ];
    NSString *characterToType = @"";
    BOOL useShift = NO;
    if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[characterString characterAtIndex:0]]) {
      useShift = YES;
      characterToType = [characterString lowercaseString];
    } else if (shift[characterString]) {
      useShift = YES;
      characterToType = shift[characterString];
    } else {
      characterToType = characterString;
    }
    NSInteger keyCode = [specialKeyCodes indexOfObject:characterToType];
    UIAHardwareKeyboard *hardwareKeyboard = [UIAHardwareKeyboard sharedHardwareKeyboard];
    if (useShift) {
      [hardwareKeyboard shiftKeyDown];
    }

    if (keyCode != NSNotFound) {
      [hardwareKeyboard pressKeyWithKeyCode:(40 + keyCode)];
    } else {
      [hardwareKeyboard pressKeyWithString:characterToType];
    }

    usleep(10000);

    if (useShift) {
      [hardwareKeyboard shiftKeyUp];
    }
  }
}

@end
