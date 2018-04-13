/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBScrolling.h"

#import "FBErrorBuilder.h"
#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBPredicate.h"
#import "XCUIApplication+FBTouchAction.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCElementSnapshot.h"
#import "XCUIApplication.h"
#import "XCUICoordinate.h"
#import "XCUICoordinate+FBFix.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

const CGFloat FBFuzzyPointThreshold = 20.f; //Smallest determined value that is not interpreted as touch
const CGFloat FBScrollToVisibleNormalizedDistance = .5f;
const CGFloat FBScrollVelocity = 200.f;
const CGFloat FBScrollBoundingVelocityPadding = 0.0f;
const CGFloat FBScrollTouchProportion = 0.75f;
const CGFloat FBScrollCoolOffTime = 1.f;
const CGFloat FBMinimumTouchEventDelay = 0.1f;

@interface XCElementSnapshot (FBScrolling)

- (void)fb_scrollUpByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application;
- (void)fb_scrollDownByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application;
- (void)fb_scrollLeftByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application;
- (void)fb_scrollRightByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application;
- (BOOL)fb_scrollByNormalizedVector:(CGVector)normalizedScrollVector inApplication:(XCUIApplication *)application;
- (BOOL)fb_scrollByVector:(CGVector)vector inApplication:(XCUIApplication *)application error:(NSError **)error;

@end

@implementation XCUIElement (FBScrolling)

- (void)fb_scrollUpByNormalizedDistance:(CGFloat)distance
{
  [self.fb_lastSnapshot fb_scrollUpByNormalizedDistance:distance inApplication:self.application];
}

- (void)fb_scrollDownByNormalizedDistance:(CGFloat)distance
{
  [self.fb_lastSnapshot fb_scrollDownByNormalizedDistance:distance inApplication:self.application];
}

- (void)fb_scrollLeftByNormalizedDistance:(CGFloat)distance
{
  [self.fb_lastSnapshot fb_scrollLeftByNormalizedDistance:distance inApplication:self.application];
}

- (void)fb_scrollRightByNormalizedDistance:(CGFloat)distance
{
  [self.fb_lastSnapshot fb_scrollRightByNormalizedDistance:distance inApplication:self.application];
}

- (BOOL)fb_scrollToVisibleWithError:(NSError **)error
{
  return [self fb_scrollToVisibleWithNormalizedScrollDistance:FBScrollToVisibleNormalizedDistance error:error];
}

- (BOOL)fb_scrollToVisibleWithNormalizedScrollDistance:(CGFloat)normalizedScrollDistance error:(NSError **)error
{
  return [self fb_scrollToVisibleWithNormalizedScrollDistance:normalizedScrollDistance
                                              scrollDirection:FBXCUIElementScrollDirectionUnknown
                                                        error:error];
}

- (BOOL)fb_scrollToVisibleWithNormalizedScrollDistance:(CGFloat)normalizedScrollDistance scrollDirection:(FBXCUIElementScrollDirection)scrollDirection error:(NSError **)error
{
  [self resolve];
  if (self.fb_isVisible) {
    return YES;
  }
  __block NSArray<XCElementSnapshot *> *cellSnapshots, *visibleCellSnapshots;

  NSArray *acceptedParents = @[
                               @(XCUIElementTypeScrollView),
                               @(XCUIElementTypeCollectionView),
                               @(XCUIElementTypeTable),
                               @(XCUIElementTypeWebView),
                               ];
  XCElementSnapshot *elementSnapshot = self.fb_lastSnapshot;
  XCElementSnapshot *scrollView = [elementSnapshot fb_parentMatchingOneOfTypes:acceptedParents
      filter:^(XCElementSnapshot *snapshot) {

         if (![snapshot isWDVisible]) {
           return NO;
         }

         cellSnapshots = [snapshot fb_descendantsCellSnapshots];

         visibleCellSnapshots = [cellSnapshots filteredArrayUsingPredicate:[FBPredicate predicateWithFormat:@"%K == YES", FBStringify(XCUIElement, fb_isVisible)]];

         if (visibleCellSnapshots.count > 1) {
           return YES;
         }
         return NO;
      }];

  if (scrollView == nil) {
    return
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"Failed to find scrollable visible parent with 2 visible children"]
     buildError:error];
  }

  XCElementSnapshot *targetCellSnapshot = [elementSnapshot fb_parentCellSnapshot];

  XCElementSnapshot *lastSnapshot = visibleCellSnapshots.lastObject;
  // Can't just do indexOfObject, because targetCellSnapshot may represent the same object represented by a member of cellSnapshots, yet be a different object
  // than that member. This reflects the fact that targetCellSnapshot came out of self.fb_parentCellSnapshot, not out of cellSnapshots directly.
  // If the result is NSNotFound, we'll just proceed by scrolling downward/rightward, since NSNotFound will always be larger than the current index.
  NSUInteger targetCellIndex = [cellSnapshots indexOfObjectPassingTest:^BOOL(XCElementSnapshot *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    return [obj _matchesElement:targetCellSnapshot];
  }];
  NSUInteger visibleCellIndex = [cellSnapshots indexOfObject:lastSnapshot];

  if (scrollDirection == FBXCUIElementScrollDirectionUnknown) {
    // Try to determine the scroll direction by determining the vector between the first and last visible cells
    XCElementSnapshot *firstVisibleCell = visibleCellSnapshots.firstObject;
    XCElementSnapshot *lastVisibleCell = visibleCellSnapshots.lastObject;
    CGVector cellGrowthVector = CGVectorMake(firstVisibleCell.frame.origin.x - lastVisibleCell.frame.origin.x,
                                             firstVisibleCell.frame.origin.y - lastVisibleCell.frame.origin.y
                                             );
    if (ABS(cellGrowthVector.dy) > ABS(cellGrowthVector.dx)) {
      scrollDirection = FBXCUIElementScrollDirectionVertical;
    } else {
      scrollDirection = FBXCUIElementScrollDirectionHorizontal;
    }
  }

  const NSUInteger maxScrollCount = 25;
  NSUInteger scrollCount = 0;

  XCElementSnapshot *prescrollSnapshot = self.fb_lastSnapshot;
  // Scrolling till cell is visible and get current value of frames
  while (![self fb_isEquivalentElementSnapshotVisible:prescrollSnapshot] && scrollCount < maxScrollCount) {
    if (targetCellIndex < visibleCellIndex) {
      scrollDirection == FBXCUIElementScrollDirectionVertical ?
        [scrollView fb_scrollUpByNormalizedDistance:normalizedScrollDistance inApplication:self.application] :
        [scrollView fb_scrollLeftByNormalizedDistance:normalizedScrollDistance inApplication:self.application];
    }
    else {
      scrollDirection == FBXCUIElementScrollDirectionVertical ?
        [scrollView fb_scrollDownByNormalizedDistance:normalizedScrollDistance inApplication:self.application] :
        [scrollView fb_scrollRightByNormalizedDistance:normalizedScrollDistance inApplication:self.application];
    }
    [self resolve]; // Resolve is needed for correct visibility
    scrollCount++;
  }

  if (scrollCount >= maxScrollCount) {
    return
    [[[FBErrorBuilder builder]
      withDescriptionFormat:@"Failed to perform scroll with visible cell due to max scroll count reached"]
     buildError:error];
  }

  // Cell is now visible, but it might be only partialy visible, scrolling till whole frame is visible
  targetCellSnapshot = [self.fb_lastSnapshot fb_parentCellSnapshot];
  CGVector scrollVector = CGVectorMake(targetCellSnapshot.visibleFrame.size.width - targetCellSnapshot.frame.size.width,
                                       targetCellSnapshot.visibleFrame.size.height - targetCellSnapshot.frame.size.height
                                       );
  if (![scrollView fb_scrollByVector:scrollVector inApplication:self.application error:error]) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_isEquivalentElementSnapshotVisible:(XCElementSnapshot *)snapshot
{
  if (self.fb_isVisible) {
    return YES;
  }
  for (XCElementSnapshot *elementSnapshot in self.application.fb_lastSnapshot._allDescendants.copy) {
    // We are comparing pre-scroll snapshot so frames are irrelevant.
    if ([snapshot fb_framelessFuzzyMatchesElement:elementSnapshot] && elementSnapshot.fb_isVisible) {
      return YES;
    }
  }
  return NO;
}

@end


@implementation XCElementSnapshot (FBScrolling)

- (CGRect)scrollingFrame
{
  return self.visibleFrame;
}

- (void)fb_scrollUpByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application
{
  [self fb_scrollByNormalizedVector:CGVectorMake(0.0, distance) inApplication:application];
}

- (void)fb_scrollDownByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application
{
  [self fb_scrollByNormalizedVector:CGVectorMake(0.0, -distance) inApplication:application];
}

- (void)fb_scrollLeftByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application
{
  [self fb_scrollByNormalizedVector:CGVectorMake(distance, 0.0) inApplication:application];
}

- (void)fb_scrollRightByNormalizedDistance:(CGFloat)distance inApplication:(XCUIApplication *)application
{
  [self fb_scrollByNormalizedVector:CGVectorMake(-distance, 0.0) inApplication:application];
}

- (BOOL)fb_scrollByNormalizedVector:(CGVector)normalizedScrollVector inApplication:(XCUIApplication *)application
{
  CGVector scrollVector = CGVectorMake(CGRectGetWidth(self.scrollingFrame) * normalizedScrollVector.dx,
                                       CGRectGetHeight(self.scrollingFrame) * normalizedScrollVector.dy
                                       );
  return [self fb_scrollByVector:scrollVector inApplication:application error:nil];
}

- (BOOL)fb_scrollByVector:(CGVector)vector inApplication:(XCUIApplication *)application error:(NSError **)error
{
  CGVector scrollBoundingVector = CGVectorMake(CGRectGetWidth(self.scrollingFrame) * FBScrollTouchProportion - FBScrollBoundingVelocityPadding,
                                               CGRectGetHeight(self.scrollingFrame)* FBScrollTouchProportion - FBScrollBoundingVelocityPadding
                                               );
  scrollBoundingVector.dx = (CGFloat)floor(copysign(scrollBoundingVector.dx, vector.dx));
  scrollBoundingVector.dy = (CGFloat)floor(copysign(scrollBoundingVector.dy, vector.dy));

  NSUInteger scrollLimit = 100;
  BOOL shouldFinishScrolling = NO;
  while (!shouldFinishScrolling) {
    CGVector scrollVector = CGVectorMake(0, 0);
    scrollVector.dx = fabs(vector.dx) > fabs(scrollBoundingVector.dx) ? scrollBoundingVector.dx : vector.dx;
    scrollVector.dy = fabs(vector.dy) > fabs(scrollBoundingVector.dy) ? scrollBoundingVector.dy : vector.dy;
    vector = CGVectorMake(vector.dx - scrollVector.dx, vector.dy - scrollVector.dy);
    shouldFinishScrolling = (vector.dx == 0.0 & vector.dy == 0.0 || --scrollLimit == 0);
    if (![self fb_scrollAncestorScrollViewByVectorWithinScrollViewFrame:scrollVector inApplication:application error:error]){
      return NO;
    }
  }
  return YES;
}

- (CGVector)fb_hitPointOffsetForScrollingVector:(CGVector)scrollingVector
{
  CGFloat x = CGRectGetMinX(self.scrollingFrame) + CGRectGetWidth(self.scrollingFrame) * (scrollingVector.dx < 0.0f ? FBScrollTouchProportion : (1 - FBScrollTouchProportion));
  CGFloat y = CGRectGetMinY(self.scrollingFrame) + CGRectGetHeight(self.scrollingFrame) * (scrollingVector.dy < 0.0f ? FBScrollTouchProportion : (1 - FBScrollTouchProportion));
  return CGVectorMake((CGFloat)floor(x), (CGFloat)floor(y));
}

- (BOOL)fb_scrollAncestorScrollViewByVectorWithinScrollViewFrame:(CGVector)vector inApplication:(XCUIApplication *)application error:(NSError **)error
{
  CGVector hitpointOffset = [self fb_hitPointOffsetForScrollingVector:vector];

  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:application normalizedOffset:CGVectorMake(0.0, 0.0)];
  XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:hitpointOffset];
  XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:startCoordinate pointsOffset:vector];

  if (FBPointFuzzyEqualToPoint(startCoordinate.fb_screenPoint, endCoordinate.fb_screenPoint, FBFuzzyPointThreshold)) {
    return YES;
  }

  NSTimeInterval scrollingTime = MAX(MAX(fabs(vector.dx), fabs(vector.dy)) / FBScrollVelocity, FBMinimumTouchEventDelay);
  NSArray<NSDictionary<NSString *, id> *> *gesture =
  @[@{
      @"action": @"longPress",
      @"options": @{
          @"x": @(startCoordinate.fb_screenPoint.x),
          @"y": @(startCoordinate.fb_screenPoint.y),
          }
      },
    @{
      @"action": @"wait",
      @"options": @{
          @"ms": @(scrollingTime * 1000),
          }
      },
    @{
      @"action": @"moveTo",
      @"options": @{
          @"x": @(endCoordinate.fb_screenPoint.x),
          @"y": @(endCoordinate.fb_screenPoint.y),
          }
      },
    @{
      @"action": @"wait",
      @"options": @{
          @"ms": @(FBMinimumTouchEventDelay * 1000),
          }
      },
    @{
      @"action": @"release"
      }
    ];
  return [application fb_performAppiumTouchActions:gesture elementCache:nil error:error];
}

@end
