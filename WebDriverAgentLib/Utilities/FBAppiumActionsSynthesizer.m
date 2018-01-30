/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAppiumActionsSynthesizer.h"

#import "FBErrorBuilder.h"
#import "FBElementCache.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBXCTestDaemonsProxy.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement.h"
#import "XCSynthesizedEventRecord.h"
#import "XCPointerEventPath.h"

static NSString *const FB_ACTION_KEY = @"action";
static NSString *const FB_ACTION_TAP = @"tap";
static NSString *const FB_ACTION_PRESS = @"press";
static NSString *const FB_ACTION_LONG_PRESS = @"longPress";
static NSString *const FB_ACTION_MOVE_TO = @"moveTo";
static NSString *const FB_ACTION_RELEASE = @"release";
static NSString *const FB_ACTION_CANCEL = @"cancel";
static NSString *const FB_ACTION_WAIT = @"wait";

static NSString *const FB_OPTION_DURATION = @"duration";
static NSString *const FB_OPTION_COUNT = @"count";
static NSString *const FB_OPTION_MS = @"ms";

// Some useful constants might be found at
// https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/view/ViewConfiguration.java
static const double FB_TAP_DURATION_MS = 100.0;
static const double FB_INTERTAP_MIN_DURATION_MS = 40.0;
static const double FB_LONG_TAP_DURATION_MS = 500.0;
static NSString *const FB_OPTIONS_KEY = @"options";
static NSString *const FB_ELEMENT_KEY = @"element";

@interface FBAppiumGestureItem : FBBaseGestureItem

@end

@interface FBTapItem : FBAppiumGestureItem

@end

@interface FBPressItem : FBAppiumGestureItem

@end

@interface FBLongPressItem : FBAppiumGestureItem

@end

@interface FBWaitItem : FBAppiumGestureItem

@end

@interface FBMoveToItem : FBAppiumGestureItem

@property (nonatomic, nonnull) NSValue *recentPosition;

@end

@interface FBReleaseItem : FBAppiumGestureItem

@end


@implementation FBAppiumGestureItem

- (nullable instancetype)initWithActionItem:(NSDictionary<NSString *, id> *)item application:(XCUIApplication *)application atPosition:(nullable NSValue *)atPosition offset:(double)offset error:(NSError **)error
{
  self = [super init];
  if (self) {
    self.actionItem = item;
    self.application = application;
    self.offset = offset;
    id options = [item objectForKey:FB_OPTIONS_KEY];
    if (atPosition) {
      self.atPosition = [atPosition CGPointValue];
    } else {
      NSValue *result = [self coordinatesWithOptions:options error:error];
      if (nil == result) {
        return nil;
      }
      self.atPosition = [result CGPointValue];
    }
    self.duration = [self durationWithOptions:options];
    if (self.duration < 0) {
      NSString *description = [NSString stringWithFormat:@"%@ value cannot be negative for '%@' action", FB_OPTION_DURATION, self.class.actionName];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
  }
  return self;
}

+ (BOOL)hasAbsolutePositioning
{
  @throw [[FBErrorBuilder.builder withDescription:@"Override this method in subclasses"] build];
  return NO;
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return (options && [options objectForKey:FB_OPTION_DURATION]) ?
    ((NSNumber *)[options objectForKey:FB_OPTION_DURATION]).doubleValue :
    0.0;
}

- (nullable NSValue *)coordinatesWithOptions:(nullable NSDictionary<NSString *, id> *)options error:(NSError **)error
{
  if (![options isKindOfClass:NSDictionary.class]) {
    NSString *description = [NSString stringWithFormat:@"'%@' key is mandatory for '%@' action", FB_OPTIONS_KEY, self.class.actionName];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  XCUIElement *element = [options objectForKey:FB_ELEMENT_KEY];
  NSNumber *x = [options objectForKey:@"x"];
  NSNumber *y = [options objectForKey:@"y"];
  if ((nil != x && nil == y) || (nil != y && nil == x) || (nil == x && nil == y && nil == element)) {
    NSString *description = [NSString stringWithFormat:@"Either '%@' or 'x' and 'y' options should be set for '%@' action", FB_ELEMENT_KEY, self.class.actionName];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  NSValue *offset = (nil != x && nil != y) ? [NSValue valueWithCGPoint:CGPointMake(x.floatValue, y.floatValue)] : nil;
  return [self hitpointWithElement:element positionOffset:offset error:error];
}

@end

@implementation FBTapItem

+ (NSString *)actionName
{
  return FB_ACTION_TAP;
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  NSTimeInterval currentOffset = FBMillisToSeconds(self.offset);
  NSMutableArray<XCPointerEventPath *> *result = [NSMutableArray array];
  XCPointerEventPath *currentPath = [[XCPointerEventPath alloc] initForTouchAtPoint:self.atPosition offset:currentOffset];
  [result addObject:currentPath];
  currentOffset += FBMillisToSeconds(FB_TAP_DURATION_MS);
  [currentPath liftUpAtOffset:currentOffset];
  
  id options = [self.actionItem objectForKey:FB_OPTIONS_KEY];
  if ([options isKindOfClass:NSDictionary.class]) {
    NSNumber *tapCount = [options objectForKey:FB_OPTION_COUNT] ?: @1;
    for (NSInteger times = 1; times < tapCount.integerValue; ++times) {
      currentOffset += FBMillisToSeconds(FB_INTERTAP_MIN_DURATION_MS);
      XCPointerEventPath *nextPath = [[XCPointerEventPath alloc] initForTouchAtPoint:self.atPosition offset:currentOffset];
      [result addObject:nextPath];
      currentOffset += FBMillisToSeconds(FB_TAP_DURATION_MS);
      [nextPath liftUpAtOffset:currentOffset];
    }
  }
  return result.copy;
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  NSNumber *tapCount = @1;
  if ([options isKindOfClass:NSDictionary.class]) {
    tapCount = [options objectForKey:FB_OPTION_COUNT] ?: tapCount;
  }
  return FB_TAP_DURATION_MS * tapCount.integerValue + FB_INTERTAP_MIN_DURATION_MS * (tapCount.integerValue - 1);
}

@end

@implementation FBPressItem

+ (NSString *)actionName
{
  return FB_ACTION_PRESS;
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  return @[[[XCPointerEventPath alloc] initForTouchAtPoint:self.atPosition offset:FBMillisToSeconds(self.offset)]];
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return 0.0;
}

@end

@implementation FBLongPressItem

+ (NSString *)actionName
{
  return FB_ACTION_LONG_PRESS;
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  return @[[[XCPointerEventPath alloc] initForTouchAtPoint:self.atPosition offset:FBMillisToSeconds(self.offset)]];
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return (options && [options objectForKey:FB_OPTION_DURATION]) ?
    ((NSNumber *)[options objectForKey:FB_OPTION_DURATION]).doubleValue :
    FB_LONG_TAP_DURATION_MS;
}

@end

@implementation FBWaitItem

+ (NSString *)actionName
{
  return FB_ACTION_WAIT;
}

+ (BOOL)hasAbsolutePositioning
{
  return NO;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  if (nil != eventPath) {
    if (0 == currentItemIndex) {
      return @[eventPath];
    }
    FBBaseGestureItem *preceedingItem = [allItems objectAtIndex:currentItemIndex - 1];
    if (![preceedingItem isKindOfClass:FBReleaseItem.class] && currentItemIndex < allItems.count - 1) {
      return @[eventPath];
    }
  }
  NSTimeInterval currentOffset = FBMillisToSeconds(self.offset + self.duration);
  XCPointerEventPath *result = [[XCPointerEventPath alloc] initForTouchAtPoint:self.atPosition offset:currentOffset];
  if (currentItemIndex == allItems.count - 1) {
    [result liftUpAtOffset:currentOffset];
  }
  return @[result];
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return (options && [options objectForKey:FB_OPTION_MS]) ?
    ((NSNumber *)[options objectForKey:FB_OPTION_MS]).doubleValue :
    0.0;
}

@end

@implementation FBMoveToItem

+ (NSString *)actionName
{
  return FB_ACTION_MOVE_TO;
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  return @[eventPath];
}

@end

@implementation FBReleaseItem

+ (NSString *)actionName
{
  return FB_ACTION_RELEASE;
}

+ (BOOL)hasAbsolutePositioning
{
  return NO;
}

- (NSArray<XCPointerEventPath *> *)addToEventPath:(XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error
{
  [eventPath liftUpAtOffset:FBMillisToSeconds(self.offset)];
  return @[eventPath];
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return 0.0;
}

@end


@interface FBAppiumGestureItemsChain : FBBaseGestureItemsChain

@end

@implementation FBAppiumGestureItemsChain

- (void)addItem:(FBBaseGestureItem *)item
{
  self.durationOffset += item.duration;
  [self.items addObject:item];
}

- (void)reset
{
  [self.items removeAllObjects];
  self.durationOffset = 0.0;
}

@end

@implementation FBAppiumActionsSynthesizer

- (NSArray<NSDictionary<NSString *, id> *> *)preprocessAction:(NSArray<NSDictionary<NSString *, id> *> *)touchActionItems
{
  NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray array];
  BOOL shouldSkipNextItem = NO;
  for (NSDictionary<NSString *, id> *touchItem in [touchActionItems reverseObjectEnumerator]) {
    id actionItemName = [touchItem objectForKey:FB_ACTION_KEY];
    if ([actionItemName isKindOfClass:NSString.class] && [actionItemName isEqualToString:FB_ACTION_CANCEL]) {
      shouldSkipNextItem = YES;;
      continue;
    }
    if (shouldSkipNextItem) {
      shouldSkipNextItem = NO;
      continue;
    }
    
    id options = [touchItem objectForKey:FB_OPTIONS_KEY];
    if (![options isKindOfClass:NSDictionary.class]) {
      [result addObject:touchItem];
      continue;
    }
    NSString *uuid = [options objectForKey:FB_ELEMENT_KEY];
    if (nil == uuid || nil == self.elementCache) {
      [result addObject:touchItem];
      continue;
    }
    XCUIElement *element = [self.elementCache elementForUUID:uuid];
    if (nil == element) {
      [result addObject:touchItem];
      continue;
    }
    NSMutableDictionary<NSString *, id> *processedItem = touchItem.mutableCopy;
    NSMutableDictionary<NSString *, id> *processedOptions = ((NSDictionary *)[processedItem objectForKey:FB_OPTIONS_KEY]).mutableCopy;
    [processedOptions setObject:element forKey:FB_ELEMENT_KEY];
    [processedItem setObject:processedOptions.copy forKey:FB_OPTIONS_KEY];
    [result addObject:processedItem.copy];
  }
  return [[result reverseObjectEnumerator] allObjects];
}

- (nullable NSArray<XCPointerEventPath *> *)eventPathsWithAction:(NSArray<NSDictionary<NSString *, id> *> *)action error:(NSError **)error
{
  static NSDictionary<NSString *, Class> *gestureItemsMapping;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableDictionary<NSString *, Class> *itemsMapping = [NSMutableDictionary dictionary];
    for (Class cls in @[FBTapItem.class,
                        FBPressItem.class,
                        FBLongPressItem.class,
                        FBMoveToItem.class,
                        FBWaitItem.class,
                        FBReleaseItem.class]) {
      [itemsMapping setObject:cls forKey:[cls actionName]];
    }
    gestureItemsMapping = itemsMapping.copy;
  });
  
  FBAppiumGestureItemsChain *chain = [[FBAppiumGestureItemsChain alloc] init];
  BOOL isAbsoluteTouchPositionSet = NO;
  for (NSDictionary<NSString *, id> *actionItem in action) {
    id actionItemName = [actionItem objectForKey:FB_ACTION_KEY];
    if (![actionItemName isKindOfClass:NSString.class]) {
      NSString *description = [NSString stringWithFormat:@"'%@' property is mandatory for gesture chain item %@", FB_ACTION_KEY, actionItem];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }

    Class gestureItemClass = [gestureItemsMapping objectForKey:actionItemName];
    if (nil == gestureItemClass) {
      NSString *description = [NSString stringWithFormat:@"%@ value '%@' is unknown", FB_ACTION_KEY, actionItemName];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    
    FBAppiumGestureItem *gestureItem = nil;
    if ([gestureItemClass hasAbsolutePositioning]) {
      gestureItem = [[gestureItemClass alloc] initWithActionItem:actionItem application:self.application atPosition:nil offset:chain.durationOffset error:error];
      isAbsoluteTouchPositionSet = YES;
    } else {
      if (!isAbsoluteTouchPositionSet) {
        if (error) {
          NSString *description = [NSString stringWithFormat:@"'%@' %@ should be preceded by an item with absolute positioning", actionItemName, FB_ACTION_KEY];
          *error = [[FBErrorBuilder.builder withDescription:description] build];
        }
        return nil;
      }
      FBBaseGestureItem *lastItem = [chain.items lastObject];
      gestureItem = [[gestureItemClass alloc] initWithActionItem:actionItem application:self.application atPosition:[NSValue valueWithCGPoint:lastItem.atPosition] offset:chain.durationOffset error:error];
    }
    if (nil == gestureItem) {
      return nil;
    }
    
    [chain addItem:gestureItem];
  }
  
  return [chain asEventPathsWithError:error];
}

- (nullable XCSynthesizedEventRecord *)synthesizeWithError:(NSError **)error
{
  XCSynthesizedEventRecord *eventRecord;
  BOOL isMultiTouch = [self.actions.firstObject isKindOfClass:NSArray.class];
  eventRecord = [[XCSynthesizedEventRecord alloc]
                 initWithName:(isMultiTouch ? @"Multi-Finger Touch Action" : @"Single-Finger Touch Action")
                 interfaceOrientation:[FBXCTestDaemonsProxy orientationWithApplication:self.application]];
  for (NSArray<NSDictionary<NSString *, id> *> *action in (isMultiTouch ? self.actions : @[self.actions])) {
    NSArray<NSDictionary<NSString *, id> *> *preprocessedAction = [self preprocessAction:action];
    NSArray<XCPointerEventPath *> *eventPaths = [self eventPathsWithAction:preprocessedAction error:error];
    if (nil == eventPaths) {
      return nil;
    }
    for (XCPointerEventPath *eventPath in eventPaths) {
      [eventRecord addPointerEventPath:eventPath];
    }
  }
  return eventRecord;
}

@end

