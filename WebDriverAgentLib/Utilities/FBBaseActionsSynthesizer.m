/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBBaseActionsSynthesizer.h"

#import "FBErrorBuilder.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "XCUIApplication+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCElementSnapshot.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCPointerEventPath.h"
#import "XCSynthesizedEventRecord.h"
#import "XCUIElement+FBUtilities.h"


@implementation FBBaseGestureItem

+ (NSString *)actionName
{
  @throw [[FBErrorBuilder.builder withDescription:@"Override this method in subclasses"] build];
  return nil;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  @throw [[FBErrorBuilder.builder withDescription:@"Override this method in subclasses"] build];
  return nil;
}

- (CGPoint)fixedHitPointWith:(CGPoint)hitPoint forSnapshot:(XCElementSnapshot *)snapshot
{
  UIInterfaceOrientation interfaceOrientation = self.application.interfaceOrientation;
  if (interfaceOrientation == UIInterfaceOrientationPortrait) {
    return hitPoint;
  }
  NSArray<XCElementSnapshot *> *ancestors = snapshot.fb_ancestors;
  XCElementSnapshot *parentWindow = ancestors.count > 1 ? [ancestors objectAtIndex:ancestors.count - 2] : nil;
  CGRect parentWindowFrame = nil == parentWindow ? snapshot.frame : parentWindow.frame;
  CGRect appFrame = self.application.frame;
  if ((appFrame.size.height > appFrame.size.width && parentWindowFrame.size.height < parentWindowFrame.size.width) ||
      (appFrame.size.height < appFrame.size.width && parentWindowFrame.size.height > parentWindowFrame.size.width)) {
    // This is the indication of the fact that transformation is broken and coordinates should be
    // recalculated manually.
    // However, upside-down case cannot be covered this way, which is not important for Appium
    hitPoint = FBInvertPointForApplication(hitPoint, appFrame.size, interfaceOrientation);
  }
  return hitPoint;
}

- (nullable NSValue *)hitpointWithElement:(nullable XCUIElement *)element positionOffset:(nullable NSValue *)positionOffset error:(NSError **)error
{
  CGPoint hitPoint;
  if (nil == element) {
    // Only absolute offset is defined
    hitPoint = [positionOffset CGPointValue];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
      /*
       Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
       even if the device is not in portait mode. That is why we need to recalculate them manually
       based on the current orientation value
       */
      hitPoint = FBInvertPointForApplication(hitPoint, self.application.frame.size, self.application.interfaceOrientation);
    }
  } else {
    // The offset relative to the element is defined
    XCElementSnapshot *snapshot = element.fb_lastSnapshot;
    CGRect frame = snapshot.frame;
    if (CGRectIsEmpty(frame)) {
      [FBLogger log:self.application.fb_descriptionRepresentation];
      NSString *description = [NSString stringWithFormat:@"The element '%@' is not visible on the screen and thus is not interactable", element.description];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    if (nil == positionOffset) {
      @try {
        // short circuit element hitpoint
        return [NSValue valueWithCGPoint:[snapshot hitPoint]];
      } @catch (NSException *e) {
        [FBLogger logFmt:@"Failed to fetch hit point for %@ - %@. Will use element frame for hit point calculation instead", element.debugDescription, e.reason];
      }
    }
    CGRect visibleFrame = snapshot.visibleFrame;
    frame = CGRectIsEmpty(visibleFrame) ? frame : visibleFrame;
    if (nil == positionOffset) {
      hitPoint = CGPointMake(frame.origin.x + frame.size.width / 2,
                             frame.origin.y + frame.size.height / 2);
    } else {
      CGPoint origin = frame.origin;
      hitPoint = CGPointMake(origin.x, origin.y);
      CGPoint offsetValue = [positionOffset CGPointValue];
      hitPoint = CGPointMake(hitPoint.x + offsetValue.x, hitPoint.y + offsetValue.y);
      // TODO: Shall we throw an exception if hitPoint is out of the element frame?
    }
    hitPoint = [self fixedHitPointWith:hitPoint forSnapshot:snapshot];
  }
  return [NSValue valueWithCGPoint:hitPoint];
}

@end


@implementation FBBaseGestureItemsChain

- (instancetype)init
{
  self = [super init];
  if (self) {
    _items = [NSMutableArray array];
    _durationOffset = 0.0;
  }
  return self;
}

- (void)addItem:(FBBaseGestureItem *)item __attribute__((noreturn))
{
  @throw [[FBErrorBuilder.builder withDescription:@"Override this method in subclasses"] build];
}

- (nullable NSArray<XCPointerEventPath *> *)asEventPathsWithError:(NSError **)error
{
  if (0 == self.items.count) {
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:@"Action items list cannot be empty"] build];
    }
    return nil;
  }
  
  NSMutableArray<XCPointerEventPath *> *result = [NSMutableArray array];
  XCPointerEventPath *previousEventPath = nil;
  XCPointerEventPath *currentEventPath = nil;
  NSUInteger index = 0;
  for (FBBaseGestureItem *item in self.items.copy) {
    NSArray<XCPointerEventPath *> *currentEventPaths = [item addToEventPath:currentEventPath
                                                                   allItems:self.items.copy
                                                           currentItemIndex:index++
                                                                      error:error];
    if (currentEventPaths == nil) {
      return nil;
    }
    currentEventPath = currentEventPaths.lastObject;
    if (currentEventPath != previousEventPath) {
      [result addObjectsFromArray:currentEventPaths];
      previousEventPath = currentEventPath;
    }
  }
  return result.copy;
}

@end


@implementation FBBaseActionsSynthesizer

- (instancetype)initWithActions:(NSArray *)actions forApplication:(XCUIApplication *)application elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error
{
  self = [super init];
  if (self) {
    if ((nil == actions || 0 == actions.count) && error) {
      *error = [[FBErrorBuilder.builder withDescription:@"Actions list cannot be empty"] build];
      return nil;
    }
    _actions = actions;
    _application = application;
    _elementCache = elementCache;
  }
  return self;
}

- (nullable XCSynthesizedEventRecord *)synthesizeWithError:(NSError **)error
{
  @throw [[FBErrorBuilder.builder withDescription:@"Override synthesizeWithError method in subclasses"] build];
  return nil;
}

@end
