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
#import "FBMacros.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCElementSnapshot.h"
#import "XCUIApplication+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

@implementation FBSpringboardApplication

+ (instancetype)fb_springboard
{
  static FBSpringboardApplication *_springboardApp;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _springboardApp = [[FBSpringboardApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.springboard"];
  });
  [_springboardApp query];
  [_springboardApp resolve];
  return _springboardApp;
}

- (BOOL)fb_tapApplicationWithIdentifier:(NSString *)identifier error:(NSError **)error
{
  XCUIElement *appElement = [[self descendantsMatchingType:XCUIElementTypeAny]
                             elementMatchingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", FBStringify(XCUIElement, identifier), identifier]
                             ];
  if (![appElement fb_scrollToVisibleWithNormalizedScrollDistance:1.0 scrollDirection:FBXCUIElementScrollDirectionHorizontal error:error]) {
    return NO;
  }
  if (![appElement fb_tapWithError:error]) {
    return NO;
  }
  return
  [[[[FBRunLoopSpinner new]
     interval:0.3]
    timeoutErrorMessage:@"Timeout waiting for application to activate"]
   spinUntilTrue:^BOOL{
     return
      [FBApplication fb_activeApplication].processID != self.processID &&
      [FBApplication fb_activeApplication].fb_mainWindowSnapshot.fb_isVisible;
   } error:error];
}

- (BOOL)fb_waitUntilApplicationBoardIsVisible:(NSError **)error
{
  return
  [[[[FBRunLoopSpinner new]
     timeout:10.]
    timeoutErrorMessage:@"Timeout waiting until SpringBoard is visible"]
   spinUntilTrue:^BOOL{
     return self.fb_isApplicationBoardVisible;
   } error:error];
}

- (BOOL)fb_isApplicationBoardVisible
{
  [self resolve];
  XCElementSnapshot *mainWindow = self.fb_mainWindowSnapshot;
  // During application switch 'SBSwitcherWindow' becomes a main window, so we should wait till it is gone
  return mainWindow.fb_isVisible && ![mainWindow.identifier isEqualToString:@"SBSwitcherWindow"];
}

@end
