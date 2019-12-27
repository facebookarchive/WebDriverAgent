/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBIsVisible.h"

#import "FBApplication.h"
#import "FBConfiguration.h"
#import "FBElementHitPoint.h"
#import "FBMathUtils.h"
#import "FBXCTestDaemonsProxy.h"
#import "XCAccessibilityElement+FBComparison.h"
#import "FBXCodeCompatibility.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBUtilities.h"
#import "XCTestManager_ManagerInterface-Protocol.h"
#import "XCTestPrivateSymbols.h"
#import <XCTest/XCUIDevice.h>
#import "XCElementSnapshot+FBHitPoint.h"
#import "XCTRunnerDaemonSession.h"

static const NSTimeInterval AX_TIMEOUT = 1.0;

@implementation XCUIElement (FBIsVisible)

- (BOOL)fb_isVisible
{
  return self.fb_lastSnapshot.fb_isVisible;
}

@end

@implementation XCElementSnapshot (FBIsVisible)


- (XCAccessibilityElement *)elementAtPoint:(CGPoint)point
{
  __block XCAccessibilityElement *result = nil;
  __block NSError *innerError = nil;
  id<XCTestManager_ManagerInterface> proxy = [FBXCTestDaemonsProxy testRunnerProxy];
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  [proxy _XCT_setAXTimeout:AX_TIMEOUT reply:^(int res) {
    [proxy _XCT_requestElementAtPoint:point
                                reply:^(XCAccessibilityElement *element, NSError *error) {
                                  if (nil == error) {
                                    result = element;
                                  } else {
                                    innerError = error;
                                  }
                                  dispatch_semaphore_signal(sem);
                                }];
  }];
  dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AX_TIMEOUT * NSEC_PER_SEC)));
  if (nil != innerError) {
    [FBLogger logFmt:@"Cannot get the accessibility element for the point where %@ snapshot is located. Original error: '%@'", innerError.description, self.description];
  }
  return result;
}

- (BOOL)fb_isVisible
{
  CGRect frame = self.frame;
  if (CGRectIsEmpty(frame)) {
    return NO;
  }
  if ([FBConfiguration shouldUseTestManagerForVisibilityDetection]) {
    return [(NSNumber *)[self fb_attributeValue:FB_XCAXAIsVisibleAttribute] boolValue];
  }
  CGRect appFrame = [self fb_rootElement].frame;
  NSArray<XCElementSnapshot *> *ancestors = self.fb_ancestors;
#if TARGET_OS_IOS
  CGSize screenSize = FBAdjustDimensionsForApplication(appFrame.size, self.application.interfaceOrientation);
#else
  CGSize screenSize = appFrame.size;
#endif
  CGRect screenFrame = CGRectMake(0, 0, screenSize.width, screenSize.height);
  if (!CGRectIntersectsRect(frame, screenFrame)) {
    return NO;
  }
  
  CGPoint midPoint = [self.suggestedHitpoints.lastObject CGPointValue];
  XCAccessibilityElement *hitElement = [self elementAtPoint:midPoint];
  if (nil != hitElement) {
    if ([self.accessibilityElement isEqualToElement:hitElement]) {
      return YES;
    }
    for (XCElementSnapshot *ancestor in ancestors) {
      if ([hitElement isEqualToElement:ancestor.accessibilityElement]) {
        return YES;
      }
    }
  }
  FBElementHitPoint *hitPoint = [self fb_hitPoint:nil];
  if (hitPoint != nil && CGRectContainsPoint(appFrame, hitPoint.point)) {
    return YES;
  }
  for (XCElementSnapshot *elementSnapshot in self.children.copy) {
    if (elementSnapshot.fb_isVisible) {
      return YES;
    }
  }
  return NO;
}

@end
