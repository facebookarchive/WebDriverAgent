// Copyright 2004-present Facebook. All Rights Reserved.

/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIApplication+SpringBoard.h"

#import "XCUIApplication.h"

@implementation XCUIApplication (SpringBoard)

+ (instancetype)fb_SpringBoard
{
  return [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.springboard"];
}

- (void)fb_tapApplicationWithIdentifier:(NSString *)identifier
{
  XCUIElement *appElement = [[self descendantsMatchingType:XCUIElementTypeAny]
                             elementMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]
                             ];
  [appElement tap];
}

@end
