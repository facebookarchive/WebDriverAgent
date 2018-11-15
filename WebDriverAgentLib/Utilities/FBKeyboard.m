/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBKeyboard.h"


#import "FBApplication.h"
#import "FBConfiguration.h"
#import "FBXCTestDaemonsProxy.h"
#import "FBErrorBuilder.h"
#import "FBRunLoopSpinner.h"
#import "FBMacros.h"
#import "FBXCodeCompatibility.h"
#import "XCElementSnapshot.h"
#import "XCUIElement+FBUtilities.h"
#import "XCTestDriver.h"
#import "FBLogger.h"
#import "FBConfiguration.h"


@implementation FBKeyboard

+ (BOOL)typeText:(NSString *)text error:(NSError **)error
{
  return [self typeText:text frequency:[FBConfiguration maxTypingFrequency] error:error];
}

+ (BOOL)typeText:(NSString *)text frequency:(NSUInteger)frequency error:(NSError **)error
{
  if (![FBKeyboard waitUntilStableWithError:error]) {
    return NO;
  }
  __block BOOL didSucceed = NO;
  __block NSError *innerError;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)(void)){
    [[FBXCTestDaemonsProxy testRunnerProxy]
     _XCT_sendString:text
     maximumFrequency:frequency
     completion:^(NSError *typingError){
       didSucceed = (typingError == nil);
       innerError = typingError;
       completion();
     }];
  }];
  if (error) {
    *error = innerError;
  }
  return didSucceed;
}

+ (BOOL)waitUntilStableWithError:(NSError **)error
{
  FBApplication *app = [FBApplication fb_activeApplication];
  
  if (![FBKeyboard waitUntilVisibleForApplication:app timeout:3 error:error]) {
    return NO;
  }
  
  if (![app fb_waitUntilFrameIsStable]) {
    return
    [[[FBErrorBuilder builder]
      withDescription:@"Timeout waiting for keybord to stop animating"]
     buildError:error];
  }
  return YES;
}

+ (BOOL)waitUntilVisibleForApplication:(XCUIApplication *)app timeout:(NSTimeInterval)timeout error:(NSError **)error
{
  BOOL (^keyboardIsVisible)(void) = ^BOOL(void) {
    XCUIElement *keyboard = [app descendantsMatchingType:XCUIElementTypeKeyboard].fb_firstMatch;
    return keyboard && keyboard.fb_isVisible;
  };
  if (timeout <= 0) {
    return keyboardIsVisible();
  }
  return
  [[[[FBRunLoopSpinner new]
     timeout:timeout]
    timeoutErrorMessage:@"Keyboard is not present"]
   spinUntilTrue:keyboardIsVisible
   error:error];
}

@end
