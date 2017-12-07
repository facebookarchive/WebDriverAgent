/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTap.h"

#import "XCUIApplication+FBTouchAction.h"
#import "XCUIElement+FBUtilities.h"


@implementation XCUIElement (FBTap)

- (BOOL)fb_tapWithError:(NSError **)error
{
  NSArray<NSDictionary<NSString *, id> *> *tapGesture =
  @[
    @{@"action": @"tap",
      @"options": @{@"element": self}
      }
    ];
  [self fb_waitUntilFrameIsStable];
  return [self.application fb_performAppiumTouchActions:tapGesture elementCache:nil error:error];
}

- (BOOL)fb_tapCoordinate:(CGPoint)relativeCoordinate error:(NSError **)error
{
  NSArray<NSDictionary<NSString *, id> *> *tapGesture =
  @[
    @{@"action": @"tap",
      @"options": @{@"element": self,
                    @"x": @(relativeCoordinate.x),
                    @"y": @(relativeCoordinate.y)
                    }
      }
    ];
  [self fb_waitUntilFrameIsStable];
  return [self.application fb_performAppiumTouchActions:tapGesture elementCache:nil error:error];
}

@end
