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
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement.h"
#import "XCSynthesizedEventRecord.h"
#import "XCTRunnerDaemonSession.h"
#import "XCPointerEventPath.h"

static const double FB_TAP_DURATION_MS = 100.0;
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
      NSString *description = [NSString stringWithFormat:@"Duration value cannot be negative for '%@' action", self.class.actionName];
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
  return (options && [options objectForKey:@"duration"]) ?
    ((NSNumber *)[options objectForKey:@"duration"]).doubleValue :
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
  return [NSValue valueWithCGPoint:[self hitpointWithElement:element positionOffset:offset]];
}

@end

@implementation FBTapItem

+ (NSString *)actionName
{
  return @"tap";
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  if (index > 0) {
    [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
    [eventPath pressDownAtOffset:FBMillisToSeconds(self.offset)];
  }
  [eventPath liftUpAtOffset:FBMillisToSeconds(self.offset + FB_TAP_DURATION_MS)];
  
  id options = [self.actionItem objectForKey:FB_OPTIONS_KEY];
  if ([options isKindOfClass:NSDictionary.class]) {
    NSNumber *tapCount = [options objectForKey:@"count"] ?: @1;
    for (NSInteger times = 1; times < tapCount.integerValue; times++) {
      [eventPath pressDownAtOffset:FBMillisToSeconds(self.offset + FB_TAP_DURATION_MS * times)];
      [eventPath liftUpAtOffset:FBMillisToSeconds(self.offset + FB_TAP_DURATION_MS * (times + 1))];
    }
  }
  return YES;
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  NSNumber *tapCount = @1;
  if ([options isKindOfClass:NSDictionary.class]) {
    tapCount = [options objectForKey:@"count"] ?: tapCount;
  }
  return FB_TAP_DURATION_MS * tapCount.integerValue;
}

- (BOOL)increaseDuration:(double)value
{
  return NO;
}

@end

@implementation FBPressItem

+ (NSString *)actionName
{
  return @"press";
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  if (index > 0) {
    [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  }
  
  id options = [self.actionItem objectForKey:FB_OPTIONS_KEY];
  NSNumber *pressure = [options isKindOfClass:NSDictionary.class] ? [options objectForKey:@"pressure"] : nil;
  if (nil == pressure) {
    [eventPath pressDownAtOffset:FBMillisToSeconds(self.offset)];
  } else {
    [eventPath pressDownWithPressure:pressure.doubleValue atOffset:FBMillisToSeconds(self.offset)];
  }
  return YES;
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return 0.0;
}

@end

@implementation FBLongPressItem

+ (NSString *)actionName
{
  return @"longPress";
}

+ (BOOL)hasAbsolutePositioning
{
  return YES;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  if (index > 0) {
    [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  }
  
  id options = [self.actionItem objectForKey:FB_OPTIONS_KEY];
  NSNumber *pressure = [options isKindOfClass:NSDictionary.class] ? [options objectForKey:@"pressure"] : nil;
  if (nil == pressure) {
    [eventPath pressDownAtOffset:FBMillisToSeconds(self.offset)];
  } else {
    [eventPath pressDownWithPressure:pressure.doubleValue atOffset:FBMillisToSeconds(self.offset)];
  }
  return YES;
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return (options && [options objectForKey:@"duration"]) ?
  ((NSNumber *)[options objectForKey:@"duration"]).doubleValue :
  FB_LONG_TAP_DURATION_MS;
}

@end

@implementation FBWaitItem

+ (NSString *)actionName
{
  return @"wait";
}

+ (BOOL)hasAbsolutePositioning
{
  return NO;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  return YES;
}

- (double)durationWithOptions:(nullable NSDictionary<NSString *, id> *)options
{
  return (options && [options objectForKey:@"ms"]) ?
  ((NSNumber *)[options objectForKey:@"ms"]).doubleValue :
  0.0;
}

@end

@implementation FBMoveToItem

- (nullable instancetype)initWithActionItem:(NSDictionary<NSString *, id> *)item application:(XCUIApplication *)application atPosition:(NSValue *)atPosition offset:(double)offset error:(NSError **)error
{
  _recentPosition = atPosition;
  
  self = [super initWithActionItem:item application:application atPosition:nil offset:offset error:error];
  if (!self) {
    return nil;
  }
  return self;
}

- (CGPoint)hitpointWithElement:(nullable XCUIElement *)element positionOffset:(nullable NSValue *)positionOffset
{
  if (nil == element) {
    // if element is not set then we consider coordinates passed to moveTo action as relative
    CGPoint recentPosition = [self.recentPosition CGPointValue];
    CGPoint offsetRelativeToRecentPosition = [positionOffset CGPointValue];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
      offsetRelativeToRecentPosition = FBInvertOffsetForOrientation(offsetRelativeToRecentPosition, self.application.interfaceOrientation);
    }
    return CGPointMake(recentPosition.x + offsetRelativeToRecentPosition.x, recentPosition.y + offsetRelativeToRecentPosition.y);
  }
  return [super hitpointWithElement:element positionOffset:positionOffset];
}

+ (NSString *)actionName
{
  return @"moveTo";
}

+ (BOOL)hasAbsolutePositioning
{
  return NO;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  return YES;
}

@end

@implementation FBReleaseItem

+ (NSString *)actionName
{
  return @"release";
}

+ (BOOL)hasAbsolutePositioning
{
  return NO;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  [eventPath liftUpAtOffset:FBMillisToSeconds(self.offset)];
  return YES;
}

- (BOOL)increaseDuration:(double)value
{
  return NO;
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
  if ([item isKindOfClass:FBWaitItem.class] && [self.items.lastObject increaseDuration:item.duration]) {
    // Merge wait duration to the recent action if possible
    return;
  }
  [self.items addObject:item];
}

- (void)reset
{
  [self.items removeAllObjects];
  self.durationOffset = 0.0;
}

@end

@implementation FBAppiumActionsSynthesizer

- (NSArray<NSDictionary<NSString *, id> *> *)preprocessAction:(NSArray<NSDictionary<NSString *, id> *> *)touchAction
{
  if (nil == self.elementCache) {
    return touchAction;
  }
  NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray array];
  for (NSDictionary<NSString *, id> *touchItem in touchAction) {
    id options = [touchItem objectForKey:FB_OPTIONS_KEY];
    if (![options isKindOfClass:NSDictionary.class] || ![options objectForKey:FB_ELEMENT_KEY]) {
      [result addObject:touchItem];
      continue;
    }
    NSMutableDictionary<NSString *, id> *processedItem = touchItem.mutableCopy;
    NSMutableDictionary<NSString *, id> *processedOptions = ((NSDictionary *)[processedItem objectForKey:FB_OPTIONS_KEY]).mutableCopy;
    NSString *uuid = [options objectForKey:FB_ELEMENT_KEY];
    XCUIElement *element = [self.elementCache elementForUUID:uuid];
    if (nil == element) {
      [result addObject:touchItem];
    } else {
      [processedOptions setObject:element forKey:FB_ELEMENT_KEY];
      [processedItem setObject:processedOptions.copy forKey:FB_OPTIONS_KEY];
      [result addObject:processedItem.copy];
    }
  }
  return result.copy;
}

- (nullable XCPointerEventPath *)eventPathWithAction:(NSArray<NSDictionary<NSString *, id> *> *)action error:(NSError **)error
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
    id actionItemName = [actionItem objectForKey:@"action"];
    if (![actionItemName isKindOfClass:NSString.class]) {
      NSString *description = [NSString stringWithFormat:@"'action' property is mandatory for gesture chain item %@", actionItem];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    
    if ([actionItemName isEqualToString:@"cancel"]) {
      [chain reset];
      continue;
    }
    
    Class gestureItemClass = [gestureItemsMapping objectForKey:actionItemName];
    if (nil == gestureItemClass) {
      NSString *description = [NSString stringWithFormat:@"Action value '%@' is unknown", actionItemName];
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
          NSString *description = [NSString stringWithFormat:@"'%@' action should be preceded by an item with absolute positioning", actionItemName];
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
  
  return [chain asEventPathWithError:error];
}

- (nullable XCSynthesizedEventRecord *)synthesizeWithError:(NSError **)error
{
  UIInterfaceOrientation orientation = self.application.interfaceOrientation;
  if (![XCTRunnerDaemonSession sharedSession].useLegacyEventCoordinateTransformationPath) {
    orientation = UIInterfaceOrientationPortrait;
  }
  XCSynthesizedEventRecord *eventRecord;
  BOOL isMultiTouch = [self.actions.firstObject isKindOfClass:NSArray.class];
  eventRecord = [[XCSynthesizedEventRecord alloc] initWithName:(isMultiTouch ? @"Multi-Finger Touch Action" : @"Single-Finger Touch Action") interfaceOrientation:orientation];
  for (NSArray<NSDictionary<NSString *, id> *> *action in (isMultiTouch ? self.actions : @[self.actions])) {
    NSArray<NSDictionary<NSString *, id> *> *preprocessedAction = [self preprocessAction:action];
    XCPointerEventPath *eventPath = [self eventPathWithAction:preprocessedAction error:error];
    if (nil == eventPath) {
      return nil;
    }
    [eventRecord addPointerEventPath:eventPath];
  }
  return eventRecord;
}

@end

