/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSpringboardApplication.h"

#import "XCUIElement+FBTap.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

@implementation FBSpringboardApplication

+ (instancetype)springboard
{
  FBSpringboardApplication *springboard = [[FBSpringboardApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.springboard"];
  [springboard query];
  [springboard resolve];
  return springboard;
}

- (void)fb_tapApplicationWithIdentifier:(NSString *)identifier
{
  XCUIElement *appElement = [[self descendantsMatchingType:XCUIElementTypeAny]
                             elementMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]
                             ];
  [appElement fb_tapWithError:nil];
}

@end
