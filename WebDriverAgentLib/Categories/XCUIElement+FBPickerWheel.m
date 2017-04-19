/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBPickerWheel.h"

#import "FBRunLoopSpinner.h"
#import "XCUICoordinate.h"

@implementation XCUIElement (FBPickerWheel)

static const NSTimeInterval VALUE_CHANGE_TIMEOUT = 2;

- (BOOL)fb_scrollWithOffset:(CGFloat)relativeHeightOffset error:(NSError **)error
{
  NSString *previousValue = self.value;
  XCUICoordinate *startCoord = [self coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  XCUICoordinate *endCoord = [startCoord coordinateWithOffset:CGVectorMake(0.0, relativeHeightOffset * self.frame.size.height)];
  [endCoord tap];
  return [[[[FBRunLoopSpinner new]
     timeout:VALUE_CHANGE_TIMEOUT]
    timeoutErrorMessage:[NSString stringWithFormat:@"Picker wheel value has not been changed after %@ seconds timeout", @(VALUE_CHANGE_TIMEOUT)]]
   spinUntilTrue:^BOOL{
     [self resolve];
     return ![self.value isEqualToString:previousValue];
   }
   error:error];
}

- (BOOL)fb_selectNextOptionWithOffset:(CGFloat)offset error:(NSError **)error
{
  return [self fb_scrollWithOffset:offset error:error];
}

- (BOOL)fb_selectPreviousOptionWithOffset:(CGFloat)offset error:(NSError **)error
{
  return [self fb_scrollWithOffset:-offset error:error];
}

@end
