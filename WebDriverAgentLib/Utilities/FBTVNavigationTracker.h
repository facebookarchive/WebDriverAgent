/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCUIElement.h>
#import "FBElement.h"

typedef NS_ENUM(NSUInteger, FBTVDirection) {
  FBTVDirectionUp     = 0,
  FBTVDirectionDown   = 1,
  FBTVDirectionLeft   = 2,
  FBTVDirectionRight  = 3,
  FBTVDirectionNone   = 4
};

NS_ASSUME_NONNULL_BEGIN

@interface FBTVNavigationTracker : NSObject

+(instancetype)trackerWithTargetElement: (id<FBElement>) targetElement;

-(FBTVDirection)directionToMoveFocuse;

@end

NS_ASSUME_NONNULL_END
