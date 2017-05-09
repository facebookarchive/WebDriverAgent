/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTyping.h"

#import "FBErrorBuilder.h"
#import "FBKeyboard.h"
#import "NSString+FBVisualLength.h"
#import "XCUIElement+FBTap.h"

@implementation XCUIElement (FBTyping)

- (BOOL)fb_typeText:(NSString *)text error:(NSError **)error
{
  if (!self.hasKeyboardFocus && ![self fb_tapWithError:error]) {
    return NO;
  }

  if (![FBKeyboard typeText:text error:error]) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_clearTextWithError:(NSError **)error
{
  while ([self.value fb_visualLength] > 0) {
    NSMutableString *textToType = @"".mutableCopy;
    const NSUInteger textLength = [self.value fb_visualLength];
    for (NSUInteger i = 0 ; i < textLength ; i++) {
      [textToType appendString:@"\b"];
    }
    if (![self fb_typeText:textToType error:error]) {
      return NO;
    }
    if ([self.value fb_visualLength] >= textLength) {
      return [[[FBErrorBuilder builder]
       withDescription:@"Failed to make any progress while clearing text"]
       buildError:error];
    }
  }
  return YES;
}

@end
