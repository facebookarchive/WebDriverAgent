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
#import "FBXCTestDaemonsProxy.h"
#import "FBErrorBuilder.h"
#import "FBRunLoopSpinner.h"
#import "FBMacros.h"
#import "XCElementSnapshot.h"
#import "XCUIElement+FBUtilities.h"
#import "XCTestDriver.h"
#import "FBLogger.h"
#import "FBConfiguration.h"

@implementation FBKeyboard

+ (BOOL)typeText:(NSString *)text error:(NSError **)error
{
  if (![FBKeyboard waitUntilVisibleWithError:error]) {
    return NO;
  }
  __block BOOL didSucceed = NO;
  __block NSError *innerError;
  [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)()){
    [[FBXCTestDaemonsProxy testRunnerProxy]
     _XCT_sendString:text
     maximumFrequency:[FBConfiguration maxTypingFrequency]
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

+ (BOOL)waitUntilVisibleWithError:(NSError **)error
{
  XCUIElement *keyboard =
  [[[[FBRunLoopSpinner new]
     timeout:5]
    timeoutErrorMessage:@"Keyboard is not present"]
   spinUntilNotNil:^id{
     XCUIElement *foundKeyboard = [[FBApplication fb_activeApplication].query descendantsMatchingType:XCUIElementTypeKeyboard].element;
     return (foundKeyboard.exists ? foundKeyboard : nil);
   }
   error:error];

  if (!keyboard) {
    return NO;
  }

  if (![keyboard fb_waitUntilFrameIsStable]) {
    return
    [[[FBErrorBuilder builder]
      withDescription:@"Timeout waiting for keybord to stop animating"]
     buildError:error];
  }
  return YES;
}

@end
