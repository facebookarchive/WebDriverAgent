/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTyping.h"

#import "FBKeyboard.h"
#import "XCUIElement+FBTap.h"

@implementation XCUIElement (FBTyping)

- (BOOL)fb_typeText:(NSString *)text maximumFrequency:(NSUInteger)freq error:(NSError **)error
{
  if (!self.hasKeyboardFocus && ![self fb_tapWithError:error]) {
    return NO;
  }

  if (![FBKeyboard typeText:text maximumFrequency:freq error:error]) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_clearTextWithError:(NSUInteger)freq error:(NSError **)error
{
  NSMutableString *textToType = @"".mutableCopy;
  const NSUInteger textLength = [self.value length];
  for (NSUInteger i = 0 ; i < textLength ; i++) {
    [textToType appendString:@"\b"];
  }
  [self fb_typeText:textToType maximumFrequency:freq error:error];
  return YES;
}

@end
