/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSpringboardApplication.h"

#import "FBRunLoopSpinner.h"
#import "XCElementSnapshot+Helpers.h"
#import "XCElementSnapshot.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBScrolling.h"
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

- (BOOL)fb_tapApplicationWithIdentifier:(NSString *)identifier error:(NSError **)error
{
  XCUIElement *appElement = [[self descendantsMatchingType:XCUIElementTypeAny]
                             elementMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]
                             ];
  if (![appElement scrollToVisibleWithNormalizedScrollDistance:1.0 error:error]) {
    return NO;
  }
  if (![appElement fb_tapWithError:error]) {
    return NO;
  }
  return YES;
}

- (BOOL)waitUntilApplicationBoardIsVisible:(NSError **)error
{
  return
  [[[[FBRunLoopSpinner new]
     timeout:10.]
    timeoutErrorMessage:@"Timeout waiting until SpringBoard is visible"]
   spinUntilTrue:^BOOL{
     return self.isApplicationBoardVisible;
   } error:error];
}

- (BOOL)isApplicationBoardVisible
{
  [self resolve];
  XCElementSnapshot *mainWindow = self.lastSnapshot.mainWindow;
  // During application switch 'SBSwitcherWindow' becomes a main window, so we should wait till it is gone
  return mainWindow.isFBVisible && ![mainWindow.identifier isEqualToString:@"SBSwitcherWindow"];
}

@end
