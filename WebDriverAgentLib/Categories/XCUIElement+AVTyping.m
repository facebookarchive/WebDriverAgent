/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+AVTyping.h"
#import "XCUIElement+AVTap.h"

#import "AVKeyboard.h"

@implementation XCUIElement (AVTyping)

- (BOOL)av_slowTypeText:(NSString *)text error:(NSError **)error
{
  if (!self.hasKeyboardFocus && ![self av_tapForClearWithError:error]) {
    return NO;
  }
  if (![AVKeyboard slowTypeText:text error:error]) {
    return NO;
  }
  return YES;
}



@end
