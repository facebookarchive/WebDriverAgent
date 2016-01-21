/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBScrolling.h"

#import <libkern/OSAtomic.h>

#import "FBWDALogger.h"
#import "XCElementSnapshot+Helpers.h"
#import "XCElementSnapshot-Hitpoint.h"
#import "XCElementSnapshot.h"
#import "XCEventGenerator.h"
#import "XCUIApplication.h"
#import "XCUICoordinate.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement.h"

const CGFloat FBNormalizedDragDistance = 0.95;
const CGFloat FBScrollVelocity = 200;
const CGFloat FBScrollBoundingVelocityPadding = 5.0;

void FBHandleScrollingErrorWithDescription(NSError **error, NSString *description);

@interface XCElementSnapshot (FBScrolling)

- (void)scrollUp;
- (void)scrollDown;
- (void)scrollLeft;
- (void)scrollRight;
- (BOOL)scrollByNormalizedVector:(CGVector)normalizedScrollVector;
- (BOOL)scrollByVector:(CGVector)vector error:(NSError **)error;

@end

@implementation XCUIElement (FBScrolling)

- (void)scrollUp
{
  [self.lastSnapshot scrollUp];
}

- (void)scrollDown
{
  [self.lastSnapshot scrollDown];
}

- (void)scrollLeft
{
  [self.lastSnapshot scrollLeft];
}

- (void)scrollRight
{
  [self.lastSnapshot scrollRight];
}

- (BOOL)scrollToVisibleWithError:(NSError **)error
{
  [self resolve];
  XCElementSnapshot *scrollView = [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeScrollView];
  scrollView = scrollView ?: [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeTable];
  scrollView = scrollView ?: [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeCollectionView];

  XCElementSnapshot *targetCellSnapshot = self.parentCellSnapshot;
  NSArray<XCElementSnapshot *> *cellSnapshots = [scrollView fb_descendantsMatchingType:XCUIElementTypeCell];
  NSArray<XCElementSnapshot *> *visibleCellSnapshots = [cellSnapshots filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isFBVisible == YES"]];

  if (visibleCellSnapshots.count < 2) {
    FBHandleScrollingErrorWithDescription(error, [NSString stringWithFormat:@"Failed to perform scroll with visible cell count %d", visibleCellSnapshots.count]);
    return NO;
  }

  NSUInteger targetCellIndex = [cellSnapshots indexOfObject:targetCellSnapshot];
  NSUInteger visibleCellIndex = [cellSnapshots indexOfObject:visibleCellSnapshots.lastObject];

  XCElementSnapshot *firsVisibleCell = visibleCellSnapshots.firstObject;
  XCElementSnapshot *lastVisibleCell = visibleCellSnapshots.lastObject;
  CGVector cellGrowthVector = CGVectorMake(firsVisibleCell.frame.origin.x - lastVisibleCell.frame.origin.x,
                                       firsVisibleCell.frame.origin.y - lastVisibleCell.frame.origin.y
                                       );

  const BOOL isVerticalScroll = (ABS(cellGrowthVector.dy) > ABS(cellGrowthVector.dx));

  const NSUInteger maxScrollCount = 25;
  NSUInteger scrollCount = 0;

  // Scrolling till cell is visible and got corrent value of frames
  while (!self.isFBVisible && scrollCount < maxScrollCount) {
    if (targetCellIndex < visibleCellIndex) {
      isVerticalScroll ? [scrollView scrollUp] : [scrollView scrollLeft];
    }
    else {
      isVerticalScroll ? [scrollView scrollDown] : [scrollView scrollRight];
    }
    [self resolve]; // Resolve is needed for correct visibility
    scrollCount++;
  }

  if (scrollCount >= maxScrollCount) {
    FBHandleScrollingErrorWithDescription(error, @"Failed to perform scroll with visible cell due to max scroll count reached");
    return NO;
  }

  // Cell is now visible, but it might be only partialy visible, scrolling till whole frame is visible
  targetCellSnapshot = self.parentCellSnapshot;
  CGVector scrollVector = CGVectorMake(targetCellSnapshot.visibleFrame.size.width - targetCellSnapshot.frame.size.width,
                                       targetCellSnapshot.visibleFrame.size.height - targetCellSnapshot.frame.size.height
                                       );
  return [scrollView scrollByVector:scrollVector error:error];
}

- (XCElementSnapshot *)parentCellSnapshot
{
  XCElementSnapshot *targetCellSnapshot = self.lastSnapshot;
  if (self.elementType != XCUIElementTypeCell) {
    targetCellSnapshot = [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeCell];
  }
  return targetCellSnapshot;
}

@end


@implementation XCElementSnapshot (FBScrolling)

- (void)scrollUp
{
  [self scrollByNormalizedVector:CGVectorMake(0.0, FBNormalizedDragDistance)];
}

- (void)scrollDown
{
  [self scrollByNormalizedVector:CGVectorMake(0.0, -FBNormalizedDragDistance)];
}

- (void)scrollLeft
{
  [self scrollByNormalizedVector:CGVectorMake(FBNormalizedDragDistance, 0.0)];
}

- (void)scrollRight
{
  [self scrollByNormalizedVector:CGVectorMake(-FBNormalizedDragDistance, 0.0)];
}


- (BOOL)scrollByNormalizedVector:(CGVector)normalizedScrollVector
{
  CGVector scrollVector = CGVectorMake(CGRectGetWidth(self.frame) * normalizedScrollVector.dx,
                                       CGRectGetHeight(self.frame) * normalizedScrollVector.dy
                                       );
  return [self scrollByVector:scrollVector error:nil];
}

- (BOOL)scrollByVector:(CGVector)vector error:(NSError **)error
{
  CGVector scrollBoundingVector = CGVectorMake(CGRectGetWidth(self.frame)/2.0 - FBScrollBoundingVelocityPadding,
                                               CGRectGetHeight(self.frame)/2.0 - FBScrollBoundingVelocityPadding
                                               );
  scrollBoundingVector.dx = copysignf(scrollBoundingVector.dx, vector.dx);
  scrollBoundingVector.dy = copysignf(scrollBoundingVector.dy, vector.dy);

  NSUInteger scrollLimit = 100;
  BOOL shouldFinishScrolling = NO;
  while (!shouldFinishScrolling) {
    CGVector scrollVector = CGVectorMake(0, 0);
    scrollVector.dx = fabs(vector.dx) > fabs(scrollBoundingVector.dx) ? scrollBoundingVector.dx : vector.dx;
    scrollVector.dy = fabs(vector.dy) > fabs(scrollBoundingVector.dy) ? scrollBoundingVector.dy : vector.dy;
    vector = CGVectorMake(vector.dx - scrollVector.dx, vector.dy - scrollVector.dy);
    shouldFinishScrolling = (vector.dx == 0.0 & vector.dy == 0.0 || --scrollLimit == 0);
    if (![self scrollAncestorScrollViewByVectorWithinScrollViewFrame:scrollVector error:error]){
      return NO;
    }
  }
  return YES;
}

- (BOOL)scrollAncestorScrollViewByVectorWithinScrollViewFrame:(CGVector)vector error:(NSError **)error
{
  CGVector hitpointOffset = CGVectorMake(self.hitPointForScrolling.x, self.hitPointForScrolling.y);
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:self.application normalizedOffset:CGVectorMake(0.0, 0.0)];
  XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:hitpointOffset];
  XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:startCoordinate pointsOffset:vector];

  if (CGPointEqualToPoint(startCoordinate.screenPoint, endCoordinate.screenPoint)) {
    return YES;
  }

  __block volatile uint32_t didFinishScrolling = 0;
  __block BOOL didSucceed = NO;
  CGFloat estimatedDuration = [[XCEventGenerator sharedGenerator] pressAtPoint:startCoordinate.screenPoint forDuration:0.0 liftAtPoint:endCoordinate.screenPoint velocity:FBScrollVelocity orientation:self.application.interfaceOrientation name:@"FBScroll" handler:^(NSError *innerError){
    didSucceed = (innerError == nil);
    if (error) {
      *error = innerError;
    }
    OSAtomicOr32Barrier(1, &didFinishScrolling);
  }];
  while (!didFinishScrolling) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:estimatedDuration/4.0]];
  }
  return didSucceed;
}

@end

void FBHandleScrollingErrorWithDescription(NSError **error, NSString *description)
{
  if (error) {
    *error = [NSError errorWithDomain:@"com.facebook.WebDriverAgent.ScrollToVisible" code:0 userInfo:@{NSLocalizedDescriptionKey : description}];
  }
}
