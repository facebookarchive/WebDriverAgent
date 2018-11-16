/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTyping.h"

#import "FBConfiguration.h"
#import "FBErrorBuilder.h"
#import "FBKeyboard.h"
#import "NSString+FBVisualLength.h"
#import "XCUIElement+FBTap.h"

@implementation XCUIElement (FBTyping)

- (BOOL)fb_typeText:(NSString *)text error:(NSError **)error
{
  return [self fb_typeText:text frequency:[FBConfiguration maxTypingFrequency] error:error];
}

- (BOOL)fb_typeText:(NSString *)text frequency:(NSUInteger)frequency error:(NSError **)error
{
  if (!self.hasKeyboardFocus && ![self fb_tapWithError:error]) {
    return NO;
  }
  if (![FBKeyboard typeText:text frequency:frequency error:error]) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_clearTextWithError:(NSError **)error
{
  NSUInteger preClearTextLength = 0;
  NSData *encodedSequence = [@"\\u0008\\u007F" dataUsingEncoding:NSASCIIStringEncoding];
  NSString *backspaceDeleteSequence = [[NSString alloc] initWithData:encodedSequence encoding:NSNonLossyASCIIStringEncoding];
  while ([self.value fb_visualLength] != preClearTextLength) {
    NSMutableString *textToType = @"".mutableCopy;
    preClearTextLength = [self.value fb_visualLength];
    for (NSUInteger i = 0 ; i < preClearTextLength ; i++) {
      [textToType appendString:backspaceDeleteSequence];
    }
    if (![self fb_typeText:textToType frequency:[FBConfiguration maxTypingFrequency] error:error]) {
      return NO;
    }
  }
  return YES;
}

@end
