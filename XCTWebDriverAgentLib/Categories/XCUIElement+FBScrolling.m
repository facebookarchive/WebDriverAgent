/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBScrolling.h"

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

@interface XCElementSnapshot (FBScrolling)

- (void)scrollByNormalizedVector:(CGVector)normalizedScrollVector;
- (void)scrollByVector:(CGVector)vector;
//- (void)scrollAncestorScrollViewByVectorWithinScrollViewFrame:(CGVector)vector;

@end

@implementation XCUIElement (FBScrolling)

- (void)scrollUp
{
  [self.lastSnapshot scrollByNormalizedVector:CGVectorMake(0.0, FBNormalizedDragDistance)];
}

- (void)scrollDown
{
  [self.lastSnapshot scrollByNormalizedVector:CGVectorMake(0.0, -FBNormalizedDragDistance)];
}

- (void)scrollLeft
{
  [self.lastSnapshot scrollByNormalizedVector:CGVectorMake(FBNormalizedDragDistance, 0.0)];
}

- (void)scrollRight
{
  [self.lastSnapshot scrollByNormalizedVector:CGVectorMake(-FBNormalizedDragDistance, 0.0)];
}

- (void)scrollToVisible
{
  NSMutableArray *visibleCells = [NSMutableArray array];
  __block XCElementSnapshot *parentCellSnapshot = nil;
  XCElementSnapshot *scrollView = [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeScrollView];
  scrollView = scrollView ?: [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeTable];
  scrollView = scrollView ?: [self.lastSnapshot fb_parentMatchingType:XCUIElementTypeCollectionView];

  [scrollView enumerateDescendantsUsingBlock:^(XCElementSnapshot *snapshot){
    if (snapshot.elementType != XCUIElementTypeCell) {
      return;
    }
    if ([snapshot _isAncestorOfElement:self.lastSnapshot]) {
      parentCellSnapshot = snapshot;
    }
    if ([snapshot _matchesElement:self.lastSnapshot]) {
      parentCellSnapshot = snapshot;
    }
    if (snapshot.isFBVisible) {
      [visibleCells addObject:snapshot];
    }
  }];

  if (visibleCells.count == 0 || parentCellSnapshot == nil) {
    return;
  }

  // Always trying to grab cell that is not in the edge (first or last)
  XCElementSnapshot *visibleCellSnapshot = visibleCells.count > 2 ? visibleCells[1] : visibleCells.lastObject;
  CGVector scrollVector = CGVectorMake(visibleCellSnapshot.frame.origin.x - parentCellSnapshot.frame.origin.x,
                                       visibleCellSnapshot.frame.origin.y - parentCellSnapshot.frame.origin.y
                                       );
  [scrollView scrollByVector:scrollVector];
}

@end


@implementation XCElementSnapshot (FBScrolling)

- (void)scrollByNormalizedVector:(CGVector)normalizedScrollVector
{
  CGVector scrollVector = CGVectorMake(CGRectGetWidth(self.frame) * normalizedScrollVector.dx,
                                       CGRectGetHeight(self.frame) * normalizedScrollVector.dy
                                       );
  [self scrollByVector:scrollVector];
}

- (void)scrollByVector:(CGVector)vector
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
    [self scrollAncestorScrollViewByVectorWithinScrollViewFrame:scrollVector];
  }
}

- (void)scrollAncestorScrollViewByVectorWithinScrollViewFrame:(CGVector)vector
{
  CGVector hitpointOffset = CGVectorMake(self.hitPointForScrolling.x, self.hitPointForScrolling.y);
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:self.application normalizedOffset:CGVectorMake(0.0, 0.0)];
  XCUICoordinate *startCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:hitpointOffset];
  XCUICoordinate *endCoordinate = [[XCUICoordinate alloc] initWithCoordinate:startCoordinate pointsOffset:vector];
  __block BOOL didFinishScrolling = NO;
  CGFloat estimatedDuration = [[XCEventGenerator sharedGenerator] pressAtPoint:startCoordinate.screenPoint forDuration:0.0 liftAtPoint:endCoordinate.screenPoint velocity:FBScrollVelocity orientation:self.application.interfaceOrientation name:@"FBScroll" handler:^(NSError *error){
    if (error) {
      [FBWDALogger logFmt:@"Failed to perform scroll: %@", error];
    }
    didFinishScrolling = YES;
  }];
  while (!didFinishScrolling) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:estimatedDuration/4.0]];
  }
}

@end
