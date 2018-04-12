/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBUtilities.h"

#import <objc/runtime.h>

#import "FBAlert.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBPredicate.h"
#import "FBRunLoopSpinner.h"
#import "FBXCodeCompatibility.h"
#import "XCAXClient_iOS.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElementQuery.h"
#import "XCTElementSetTransformer-Protocol.h"


@implementation XCUIElement (FBUtilities)

static const NSTimeInterval FBANIMATION_TIMEOUT = 5.0;

- (BOOL)fb_waitUntilFrameIsStable
{
  __block CGRect frame = self.frame;
  // Initial wait
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  return
  [[[FBRunLoopSpinner new]
     timeout:10.]
   spinUntilTrue:^BOOL{
     const BOOL isSameFrame = FBRectFuzzyEqualToRect(self.frame, frame, FBDefaultFrameFuzzyThreshold);
     frame = self.frame;
     return isSameFrame;
   }];
}

- (BOOL)fb_isObstructedByAlert
{
  return [[FBAlert alertWithApplication:self.application].alertElement fb_obstructsElement:self];
}

- (BOOL)fb_obstructsElement:(XCUIElement *)element
{
  if (!self.exists) {
    return NO;
  }
  XCElementSnapshot *snapshot = self.fb_lastSnapshot;
  XCElementSnapshot *elementSnapshot = element.fb_lastSnapshot;
  if ([snapshot _isAncestorOfElement:elementSnapshot]) {
    return NO;
  }
  if ([snapshot _matchesElement:elementSnapshot]) {
    return NO;
  }
  return YES;
}

static BOOL FBShouldUseSnapshotForDebugDescription = NO;
static dispatch_once_t onceUseSnapshotForDebugDescriptionToken;

- (XCElementSnapshot *)fb_lastSnapshot
{
  XCUIElementQuery *query = [self query];
  dispatch_once(&onceUseSnapshotForDebugDescriptionToken, ^{
    FBShouldUseSnapshotForDebugDescription = [query respondsToSelector:NSSelectorFromString(@"elementSnapshotForDebugDescription")];
  });
  if (FBShouldUseSnapshotForDebugDescription) {
    return (XCElementSnapshot *)[query valueForKey:@"elementSnapshotForDebugDescription"];
  }
  [self resolve];
  return self.lastSnapshot;
}

- (XCElementSnapshot *)fb_lastSnapshotFromQuery
{
  XCElementSnapshot *snapshot = nil;
  @try {
    XCUIElementQuery *rootQuery = self.query;
    while (rootQuery != nil && rootQuery.rootElementSnapshot == nil) {
      rootQuery = rootQuery.inputQuery;
    }
    if (rootQuery != nil) {
      NSMutableArray *snapshots = [NSMutableArray arrayWithObject:rootQuery.rootElementSnapshot];
      [snapshots addObjectsFromArray:rootQuery.rootElementSnapshot._allDescendants];
      NSOrderedSet *matchingSnapshots = (NSOrderedSet *)[self.query.transformer transform:[NSOrderedSet orderedSetWithArray:snapshots] relatedElements:nil];
      if (matchingSnapshots != nil && matchingSnapshots.count == 1) {
        snapshot = matchingSnapshots[0];
      }
    }
  } @catch (NSException *) {
    snapshot = nil;
  }
  return snapshot ?: self.fb_lastSnapshot;
}

- (NSArray<XCUIElement *> *)fb_filterDescendantsWithSnapshots:(NSArray<XCElementSnapshot *> *)snapshots
{
  if (0 == snapshots.count) {
    return @[];
  }
  NSArray<NSString *> *matchedUids = [snapshots valueForKey:FBStringify(XCUIElement, wdUID)];
  NSMutableArray<XCUIElement *> *matchedElements = [NSMutableArray array];
  if ([matchedUids containsObject:self.wdUID]) {
    if (1 == snapshots.count) {
      return @[self];
    }
    [matchedElements addObject:self];
  }
  XCUIElementType type = XCUIElementTypeAny;
  NSArray<NSNumber *> *uniqueTypes = [snapshots valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOfObjects.%@", FBStringify(XCUIElement, elementType)]];
  if (uniqueTypes && [uniqueTypes count] == 1) {
    type = [uniqueTypes.firstObject intValue];
  }
  XCUIElementQuery *query = [[self descendantsMatchingType:type] matchingPredicate:[FBPredicate predicateWithFormat:@"%K IN %@", FBStringify(XCUIElement, wdUID), matchedUids]];
  if (1 == snapshots.count) {
    XCUIElement *result = query.fb_firstMatch;
    return result ? @[result] : @[];
  }
  [matchedElements addObjectsFromArray:query.allElementsBoundByAccessibilityElement];
  if (matchedElements.count <= 1) {
    // There is no need to sort elements if count of matches is not greater than one
    return matchedElements.copy;
  }
  NSMutableArray<XCUIElement *> *sortedElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    XCUIElement *matchedElement = nil;
    for (XCUIElement *element in matchedElements) {
      if ([element.wdUID isEqualToString:snapshot.wdUID]) {
        matchedElement = element;
        break;
      }
    }
    if (matchedElement) {
      [sortedElements addObject:matchedElement];
      [matchedElements removeObject:matchedElement];
    }
  }];
  return sortedElements.copy;
}

- (BOOL)fb_waitUntilSnapshotIsStable
{
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  [[XCAXClient_iOS sharedClient] notifyWhenNoAnimationsAreActiveForApplication:self.application reply:^{dispatch_semaphore_signal(sem);}];
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(FBANIMATION_TIMEOUT * NSEC_PER_SEC));
  BOOL result = 0 == dispatch_semaphore_wait(sem, timeout);
  if (!result) {
    [FBLogger logFmt:@"There are still some active animations in progress after %.2f seconds timeout. Visibility detection may cause unexpected delays.", FBANIMATION_TIMEOUT];
  }
  return result;
}

- (NSData *)fb_screenshotWithError:(NSError **)error
{
  if (CGRectIsEmpty(self.frame)) {
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:@"Cannot get a screenshot of zero-sized element"] build];
    }
    return nil;
  }

  Class xcScreenClass = NSClassFromString(@"XCUIScreen");
  if (nil == xcScreenClass) {
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:@"Element screenshots are only available since Xcode9 SDK"] build];
    }
    return nil;
  }

  id mainScreen = [xcScreenClass valueForKey:@"mainScreen"];
  SEL mSelector = NSSelectorFromString(@"screenshotDataForQuality:rect:error:");
  NSMethodSignature *mSignature = [mainScreen methodSignatureForSelector:mSelector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:mSignature];
  [invocation setTarget:mainScreen];
  [invocation setSelector:mSelector];
  NSUInteger quality = 1;
  [invocation setArgument:&quality atIndex:2];
  CGRect elementRect = self.frame;
  UIInterfaceOrientation orientation = self.application.interfaceOrientation;
  if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
    // Workaround XCTest bug when element frame is returned as in portrait mode even if the screenshot is rotated
    XCElementSnapshot *selfSnapshot = self.fb_lastSnapshot;
    NSArray<XCElementSnapshot *> *ancestors = selfSnapshot.fb_ancestors;
    XCElementSnapshot *parentWindow = nil;
    if (1 == ancestors.count) {
      parentWindow = selfSnapshot;
    } else if (ancestors.count > 1) {
      parentWindow = [ancestors objectAtIndex:ancestors.count - 2];
    }
    if (nil != parentWindow) {
      CGRect appFrame = ancestors.lastObject.frame;
      CGRect parentWindowFrame = parentWindow.frame;
      if (CGRectEqualToRect(appFrame, parentWindowFrame)
          || (appFrame.size.width > appFrame.size.height && parentWindowFrame.size.width > parentWindowFrame.size.height)
          || (appFrame.size.width < appFrame.size.height && parentWindowFrame.size.width < parentWindowFrame.size.height)) {
        CGPoint fixedOrigin = orientation == UIInterfaceOrientationLandscapeLeft ?
          CGPointMake(appFrame.size.height - elementRect.origin.y - elementRect.size.height, elementRect.origin.x) :
          CGPointMake(elementRect.origin.y, appFrame.size.width - elementRect.origin.x - elementRect.size.width);
        elementRect = CGRectMake(fixedOrigin.x, fixedOrigin.y, elementRect.size.height, elementRect.size.width);
      }
    }
  }
  [invocation setArgument:&elementRect atIndex:3];
  [invocation setArgument:&error atIndex:4];
  [invocation invoke];
  NSData __unsafe_unretained *imageData;
  [invocation getReturnValue:&imageData];
  if (nil == imageData) {
    return nil;
  }
  return FBAdjustScreenshotOrientationForApplication(imageData, orientation);
}

@end
