/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTVFocuse.h"

#import <XCTest/XCUIRemote.h>
#import "XCUIApplication+FBFocused.h"
#import "FBApplication.h"
#import "FBErrorBuilder.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElement+FBUtilities.h"
#import "FBMathUtils.h"

int const MAX_ITERATIONS_COUNT = 100;

typedef NS_ENUM(NSUInteger, FBTVDirection) {
  FBTVDirectionUp     = 0,
  FBTVDirectionDown   = 1,
  FBTVDirectionLeft   = 2,
  FBTVDirectionRight  = 3,
  FBTVDirectionNone   = 4
};

@interface FBTVNavigationItem : NSObject
@property (nonatomic, assign) NSUInteger uid;
@property (nonatomic, strong) NSMutableSet<NSNumber *>* directions;

+(instancetype)itemWithUid:(NSUInteger) uid;
@end

@implementation FBTVNavigationItem

+(instancetype)itemWithUid:(NSUInteger) uid
{
  return [[FBTVNavigationItem alloc] initWithUid:uid];
}

-(instancetype)initWithUid:(NSUInteger) uid
{
  self = [super init];
  if(self) {
    _uid = uid;
    _directions = [NSMutableSet set];
  }
  return self;
}

@end


@interface FBTVNavigationTracker : NSObject

+(instancetype)trackerWithTargetElement: (XCUIElement*) targetElement;

-(FBTVDirection)directionToMoveFocuse;

@end

@interface FBTVNavigationTracker ()
@property (nonatomic, strong) XCUIElement *targetElement;
@property (nonatomic, assign) CGPoint targetCenter;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, FBTVNavigationItem* >* navigationItems;
@end

@implementation FBTVNavigationTracker

+(instancetype)trackerWithTargetElement: (XCUIElement*) targetElement
{
  FBTVNavigationTracker *tracker = [[FBTVNavigationTracker alloc] initWithTargetElement:targetElement];
  tracker.targetElement = targetElement;
  return tracker;
}

-(instancetype)initWithTargetElement: (XCUIElement*) targetElement
{
  self = [super init];
  if(self) {
    _targetElement = targetElement;
    _targetCenter = FBRectGetCenter(targetElement.frame);
    _navigationItems = [NSMutableDictionary dictionary];
  }
  return self;
}

-(FBTVDirection)directionToMoveFocuse
{
  XCUIElement *focused = [FBApplication fb_activeApplication].fb_focusedElement;
  CGPoint focusedCenter = FBRectGetCenter(focused.frame);
  FBTVNavigationItem *item = [self navigationItemFromElement:focused];
  CGFloat yDelta = self.targetCenter.y - focusedCenter.y;
  CGFloat xDelta = self.targetCenter.x - focusedCenter.x;
  FBTVDirection direction;
  if(fabs(yDelta) > fabs(xDelta)) {
    direction = [self getVerticalDirectionForItem:item withDelta:yDelta];
    if (direction == FBTVDirectionNone) {
      direction = [self getHorizontalDirectionForItem:item withDelta:xDelta];
    }
  } else {
    direction = [self getHorizontalDirectionForItem:item withDelta:xDelta];
    if (direction == FBTVDirectionNone) {
      direction = [self getVerticalDirectionForItem:item withDelta:yDelta];
    }
  }
  
  return direction;
}

#pragma mark - Utilities
-(FBTVNavigationItem*) navigationItemFromElement:(XCUIElement*) element
{
  NSNumber *key = [NSNumber numberWithUnsignedInteger:element.wdUID];
  FBTVNavigationItem* item = [self.navigationItems objectForKey: key];
  if(item) {
    return item;
  }
  item = [FBTVNavigationItem itemWithUid:element.wdUID];
  [self.navigationItems setObject:item forKey:key];
  return item;
}

-(FBTVDirection)getHorizontalDirectionForItem:(FBTVNavigationItem *)item withDelta:(CGFloat)delta {
  if (delta > 0) {
    if(![item.directions containsObject: [NSNumber numberWithInteger: FBTVDirectionRight]]) {
      [item.directions addObject: [NSNumber numberWithInteger: FBTVDirectionRight]];
      return FBTVDirectionRight;
    }
  }
  if (delta < 0) {
    if(![item.directions containsObject: [NSNumber numberWithInteger: FBTVDirectionLeft]]) {
      [item.directions addObject: [NSNumber numberWithInteger: FBTVDirectionLeft]];
      return FBTVDirectionLeft;
    }
  }
  return FBTVDirectionNone;
}

-(FBTVDirection)getVerticalDirectionForItem:(FBTVNavigationItem *)item withDelta:(CGFloat)delta {
  if (delta > 0) {
    if(![item.directions containsObject: [NSNumber numberWithInteger: FBTVDirectionDown]]) {
      [item.directions addObject: [NSNumber numberWithInteger: FBTVDirectionDown]];
      return FBTVDirectionDown;
    }
  }
  if (delta < 0) {
    if(![item.directions containsObject: [NSNumber numberWithInteger: FBTVDirectionUp]]) {
      [item.directions addObject: [NSNumber numberWithInteger: FBTVDirectionUp]];
      return FBTVDirectionUp;
    }
  }
  return FBTVDirectionNone;
}

@end

@implementation XCUIElement (FBTVFocuse)

-(BOOL)fb_focuseWithError:(NSError**) error
{
  [[FBApplication fb_activeApplication] fb_waitUntilSnapshotIsStable];
  if (self.wdEnabled) {
    FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:self];
    for (int i = 0; i < MAX_ITERATIONS_COUNT; i++) {
      if (self.hasFocus) {
        return YES;
      }
      if (self.exists) {
        FBTVDirection direction = tracker.directionToMoveFocuse;
        if(direction != FBTVDirectionNone) {
          [[XCUIRemote sharedRemote] pressButton: (XCUIRemoteButton)direction];
          continue;
        }
      }
      [[[FBErrorBuilder builder] withDescription:@"Unable to reach element. Try to use XCUIRemote commands."]
       buildError:error];
      return NO;
    }
  }
  [[[FBErrorBuilder builder] withDescription:@"Element could not be focused."]
   buildError:error];
  return NO;
}

-(BOOL)fb_selectWithError:(NSError**) error
{
  BOOL result = [self fb_focuseWithError: error];
  if (result) {
    [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonSelect];
  }
  return result;
}
@end
