/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBW3CActionsSynthesizer.h"

#import "FBErrorBuilder.h"
#import "FBElementCache.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "XCElementSnapshot+FBHitPoint.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement.h"
#import "XCSynthesizedEventRecord.h"
#import "XCTRunnerDaemonSession.h"
#import "XCPointerEventPath.h"


static NSString *const FB_KEY_TYPE = @"type";
static NSString *const FB_ACTION_TYPE_POINTER = @"pointer";
static NSString *const FB_ACTION_TYPE_KEY = @"key";
static NSString *const FB_ACTION_TYPE_NONE = @"none";

static NSString *const FB_PARAMETERS_KEY_POINTER_TYPE = @"pointerType";
static NSString *const FB_POINTER_TYPE_MOUSE = @"mouse";
static NSString *const FB_POINTER_TYPE_PEN = @"pen";
static NSString *const FB_POINTER_TYPE_TOUCH = @"touch";

static NSString *const FB_ACTION_ITEM_KEY_ORIGIN = @"origin";
static NSString *const FB_ORIGIN_TYPE_VIEWPORT = @"viewport";
static NSString *const FB_ORIGIN_TYPE_POINTER = @"pointer";

static NSString *const FB_ACTION_ITEM_KEY_TYPE = @"type";
static NSString *const FB_ACTION_ITEM_TYPE_POINTER_MOVE = @"pointerMove";
static NSString *const FB_ACTION_ITEM_TYPE_POINTER_DOWN = @"pointerDown";
static NSString *const FB_ACTION_ITEM_TYPE_POINTER_UP = @"pointerUp";
static NSString *const FB_ACTION_ITEM_TYPE_POINTER_CANCEL = @"pointerCancel";
static NSString *const FB_ACTION_ITEM_TYPE_PAUSE = @"pause";

static NSString *const FB_ACTION_ITEM_KEY_DURATION = @"duration";
static NSString *const FB_ACTION_ITEM_KEY_X = @"x";
static NSString *const FB_ACTION_ITEM_KEY_Y = @"y";
static NSString *const FB_ACTION_ITEM_KEY_BUTTON = @"button";
static NSString *const FB_ACTION_ITEM_KEY_PRESSURE = @"pressure";

static NSString *const FB_KEY_ID = @"id";
static NSString *const FB_KEY_PARAMETERS = @"parameters";
static NSString *const FB_KEY_ACTIONS = @"actions";


@interface FBW3CGestureItem : FBBaseGestureItem

@property (nullable, readonly, nonatomic) FBBaseGestureItem *previousItem;

@end

@interface FBPointerDownItem : FBW3CGestureItem

@property (readonly, nonatomic) double pressure;

@end

@interface FBPauseItem : FBW3CGestureItem

@end

@interface FBPointerMoveItem : FBW3CGestureItem

@end

@interface FBPointerUpItem : FBW3CGestureItem

@end


@implementation FBW3CGestureItem

- (nullable instancetype)initWithActionItem:(NSDictionary<NSString *, id> *)actionItem application:(XCUIApplication *)application previousItem:(nullable FBBaseGestureItem *)previousItem offset:(double)offset error:(NSError **)error
{
  self = [super init];
  if (self) {
    self.actionItem = actionItem;
    self.application = application;
    self.offset = offset;
    _previousItem = previousItem;
    self.duration = 0.0;
    NSNumber *durationObj = [actionItem objectForKey:FB_ACTION_ITEM_KEY_DURATION];
    if (nil != durationObj && [self increaseDuration:[durationObj doubleValue]] && self.duration < 0.0) {
      NSString *description = [NSString stringWithFormat:@"Duration value cannot be negative for '%@' action item", self.actionItem];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    NSValue *position = [self positionWithError:error];
    if (nil == position) {
      return nil;
    }
    self.atPosition = [position CGPointValue];
  }
  return self;
}

- (nullable NSValue *)positionWithError:(NSError **)error
{
  if (nil == self.previousItem) {
    NSString *errorDescription = [NSString stringWithFormat:@"The '%@' action item must be preceded by %@ item", self.actionItem, FB_ACTION_ITEM_TYPE_POINTER_MOVE];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:errorDescription] build];
    }
    return nil;
  }
  return [NSValue valueWithCGPoint:self.previousItem.atPosition];
}

- (nullable NSValue *)hitpointWithElement:(nullable XCUIElement *)element positionOffset:(nullable NSValue *)positionOffset error:(NSError **)error
{
  CGPoint hitPoint;
  if (nil == element) {
    // Only absolute offset is defined
    hitPoint = [positionOffset CGPointValue];
  } else {
    // An offset relative to the element is defined
    XCElementSnapshot *snapshot = element.fb_lastSnapshot;
    if (CGRectIsEmpty(snapshot.fb_frameInWindow)) {
      NSString *description = [NSString stringWithFormat:@"The element '%@' is not visible on the screen", element.debugDescription];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    CGRect frame = snapshot.frame;
    hitPoint = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
    if (nil != positionOffset) {
      CGPoint offsetValue = [positionOffset CGPointValue];
      hitPoint = CGPointMake(hitPoint.x + offsetValue.x, hitPoint.y + offsetValue.y);
      // TODO: Shall we throw an exception if hitPoint is out of the element frame?
    }
  }
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    /*
     Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
     even if the device is not in portait mode. That is why we need to recalculate them manually
     based on the current orientation value
     */
    hitPoint = FBInvertPointForApplication(hitPoint, self.application.frame.size, self.application.interfaceOrientation);
  }
  return [NSValue valueWithCGPoint:hitPoint];
}

@end

@implementation FBPointerDownItem

- (nullable instancetype)initWithActionItem:(NSDictionary<NSString *, id> *)actionItem application:(XCUIApplication *)application previousItem:(nullable FBBaseGestureItem *)previousItem offset:(double)offset error:(NSError **)error
{
  self = [super initWithActionItem:actionItem application:application previousItem:previousItem offset:offset error:error];
  if (self) {
    _pressure = 0.0;
    NSNumber *pressureObj = [actionItem objectForKey:FB_ACTION_ITEM_KEY_PRESSURE];
    if (nil != pressureObj) {
      _pressure = [pressureObj doubleValue];
    }
  }
  return self;
}

+ (NSString *)actionName
{
  return FB_ACTION_ITEM_TYPE_POINTER_DOWN;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  if (index > 0) {
    [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  }
  if (self.pressure > 0.0) {
    [eventPath pressDownWithPressure:self.pressure atOffset:FBMillisToSeconds(self.offset)];
  } else {
    [eventPath pressDownAtOffset:FBMillisToSeconds(self.offset)];
  }
  return YES;
}

- (BOOL)increaseDuration:(double)value
{
  return NO;
}

@end

@implementation FBPointerMoveItem

- (nullable NSValue *)positionWithError:(NSError **)error
{
  static NSArray<NSString *> *supportedOriginTypes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    supportedOriginTypes = @[FB_ORIGIN_TYPE_POINTER, FB_ORIGIN_TYPE_VIEWPORT];
  });
  id origin = [self.actionItem objectForKey:FB_ACTION_ITEM_KEY_ORIGIN] ?: FB_ORIGIN_TYPE_VIEWPORT;
  BOOL isOriginAnElement = [origin isKindOfClass:XCUIElement.class] && [(XCUIElement *)origin exists];
  if (!isOriginAnElement && ![supportedOriginTypes containsObject:origin]) {
    NSString *description = [NSString stringWithFormat:@"Unsupported %@ type '%@' is set for '%@' action item. Supported origin types: %@ or an element instance", FB_ACTION_ITEM_KEY_ORIGIN, origin, self.actionItem, supportedOriginTypes];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  
  XCUIElement *element = isOriginAnElement ? (XCUIElement *)origin : nil;
  NSNumber *x = [self.actionItem objectForKey:FB_ACTION_ITEM_KEY_X];
  NSNumber *y = [self.actionItem objectForKey:FB_ACTION_ITEM_KEY_Y];
  if ((nil != x && nil == y) || (nil != y && nil == x) ||
      ([origin isKindOfClass:NSString.class] && [origin isEqualToString:FB_ORIGIN_TYPE_VIEWPORT] && (nil == x || nil == y))) {
    NSString *errorDescription = [NSString stringWithFormat:@"Both 'x' and 'y' options should be set for '%@' action item", self.actionItem];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:errorDescription] build];
    }
    return nil;
  }
  
  if (nil != element) {
    if (nil == x && nil == y) {
      return [self hitpointWithElement:element positionOffset:nil error:error];
    }
    return [self hitpointWithElement:element positionOffset:[NSValue valueWithCGPoint:CGPointMake(x.floatValue, y.floatValue)] error:error];
  }
  
  if ([origin isKindOfClass:NSString.class] && [origin isEqualToString:FB_ORIGIN_TYPE_VIEWPORT]) {
    return [self hitpointWithElement:nil positionOffset:[NSValue valueWithCGPoint:CGPointMake(x.floatValue, y.floatValue)] error:error];
  }
  
  // origin == FB_ORIGIN_TYPE_POINTER
  if (nil == self.previousItem) {
    NSString *errorDescription = [NSString stringWithFormat:@"There is no previous item for '%@' action item, however %@ is set to '%@'", self.actionItem, FB_ACTION_ITEM_KEY_ORIGIN, FB_ORIGIN_TYPE_POINTER];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:errorDescription] build];
    }
    return nil;
  }
  CGPoint recentPosition = self.previousItem.atPosition;
  CGPoint offsetRelativeToRecentPosition = (nil == x && nil == y) ? CGPointMake(0.0, 0.0) : CGPointMake(x.floatValue, y.floatValue);
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    offsetRelativeToRecentPosition = FBInvertOffsetForOrientation(offsetRelativeToRecentPosition, self.application.interfaceOrientation);
  }
  return [NSValue valueWithCGPoint:CGPointMake(recentPosition.x + offsetRelativeToRecentPosition.x, recentPosition.y + offsetRelativeToRecentPosition.y)];
}

+ (NSString *)actionName
{
  return FB_ACTION_ITEM_TYPE_POINTER_MOVE;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  return YES;
}

@end

@implementation FBPauseItem

+ (NSString *)actionName
{
  return FB_ACTION_ITEM_TYPE_PAUSE;
}

- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error
{
  [eventPath moveToPoint:self.atPosition atOffset:FBMillisToSeconds(self.offset)];
  return YES;
}

@end

@implementation FBPointerUpItem

+ (NSString *)actionName
{
  return FB_ACTION_ITEM_TYPE_POINTER_UP;
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

@end


@interface FBW3CGestureItemsChain : FBBaseGestureItemsChain

@end

@implementation FBW3CGestureItemsChain

- (void)addItem:(FBBaseGestureItem *)item
{
  self.durationOffset += item.duration;
  if ([item isKindOfClass:FBPauseItem.class] && [self.items.lastObject increaseDuration:item.duration]) {
    // Merge wait duration to the recent action if possible
    return;
  }
  [self.items addObject:item];
}

@end

@implementation FBW3CActionsSynthesizer

- (NSArray<NSDictionary<NSString *, id> *> *)preprocessedActionItemsWith:(NSArray<NSDictionary<NSString *, id> *> *)actionItems
{
  NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray array];
  BOOL shouldCancelNextItem = NO;
  for (NSDictionary<NSString *, id> *actionItem in [actionItems reverseObjectEnumerator]) {
    if (shouldCancelNextItem) {
      shouldCancelNextItem = NO;
      continue;
    }
    NSString *actionItemType = [actionItem objectForKey:FB_ACTION_ITEM_KEY_TYPE];
    if (actionItemType != nil && [actionItemType isEqualToString:FB_ACTION_ITEM_TYPE_POINTER_CANCEL]) {
      shouldCancelNextItem = YES;
      continue;
    }
    
    if (nil == self.elementCache) {
      [result addObject:actionItem];
      continue;
    }
    id origin = [actionItem objectForKey:FB_ACTION_ITEM_KEY_ORIGIN];
    if (nil == origin || [@[FB_ORIGIN_TYPE_POINTER, FB_ORIGIN_TYPE_VIEWPORT] containsObject:origin]) {
      [result addObject:actionItem];
      continue;
    }
    // Selenium Python client passes 'origin' element in the following format:
    //
    // if isinstance(origin, WebElement):
    //    action["origin"] = {"element-6066-11e4-a52e-4f735466cecf": origin.id}
    if ([origin isKindOfClass:NSDictionary.class]) {
      for (NSString* key in [origin copy]) {
        if ([[key lowercaseString] containsString:@"element"]) {
          origin = [origin objectForKey:key];
          break;
        }
      }
    }
    XCUIElement *instance = [self.elementCache elementForUUID:origin];
    if (nil == instance) {
      [result addObject:actionItem];
      continue;
    }
    NSMutableDictionary<NSString *, id> *processedItem = actionItem.mutableCopy;
    [processedItem setObject:instance forKey:FB_ACTION_ITEM_KEY_ORIGIN];
    [result addObject:processedItem.copy];
  }
  return [[result reverseObjectEnumerator] allObjects];
}

- (nullable XCPointerEventPath *)eventPathWithActionDescription:(NSDictionary<NSString *, id> *)actionDescription forActionId:(NSString *)actionId error:(NSError **)error
{
  static NSDictionary<NSString *, Class> *gestureItemsMapping;
  static NSArray<NSString *> *supportedActionItemTypes;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableDictionary<NSString *, Class> *itemsMapping = [NSMutableDictionary dictionary];
    for (Class cls in @[FBPointerDownItem.class,
                        FBPointerMoveItem.class,
                        FBPauseItem.class,
                        FBPointerUpItem.class]) {
      [itemsMapping setObject:cls forKey:[cls actionName]];
    }
    gestureItemsMapping = itemsMapping.copy;
    supportedActionItemTypes = @[FB_ACTION_ITEM_TYPE_PAUSE,
                                 FB_ACTION_ITEM_TYPE_POINTER_UP,
                                 FB_ACTION_ITEM_TYPE_POINTER_DOWN,
                                 FB_ACTION_ITEM_TYPE_POINTER_MOVE];
  });
  
  id actionType = [actionDescription objectForKey:FB_KEY_TYPE];
  if (![actionType isKindOfClass:NSString.class] || ![actionType isEqualToString:FB_ACTION_TYPE_POINTER]) {
    NSString *description = [NSString stringWithFormat:@"Only actions of '%@' type are supported. '%@' is given instead for action with id '%@'", FB_ACTION_TYPE_POINTER, actionType, actionId];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  
  id parameters = [actionDescription objectForKey:FB_KEY_PARAMETERS];
  id pointerType = FB_POINTER_TYPE_MOUSE;
  if ([parameters isKindOfClass:NSDictionary.class]) {
    pointerType = [parameters objectForKey:FB_PARAMETERS_KEY_POINTER_TYPE] ?: FB_POINTER_TYPE_MOUSE;
  }
  if (![pointerType isKindOfClass:NSString.class] || ![pointerType isEqualToString:FB_POINTER_TYPE_TOUCH]) {
    NSString *description = [NSString stringWithFormat:@"Only pointer type '%@' is supported. '%@' is given instead for action with id '%@'", FB_POINTER_TYPE_TOUCH, pointerType, actionId];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  
  NSArray<NSDictionary<NSString *, id> *> *actionItems = [actionDescription objectForKey:FB_KEY_ACTIONS];
  if (nil == actionItems || 0 == actionItems.count) {
   NSString *description = [NSString stringWithFormat:@"It is mandatory to have at least one gesture item defined for each action. Action with id '%@' contains none", actionId];
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:description] build];
    }
    return nil;
  }
  
  FBW3CGestureItemsChain *chain = [[FBW3CGestureItemsChain alloc] init];
  NSArray<NSDictionary<NSString *, id> *> *processedItems = [self preprocessedActionItemsWith:actionItems];
  for (NSDictionary<NSString *, id> *actionItem in processedItems) {
    id actionItemType = [actionItem objectForKey:FB_ACTION_ITEM_KEY_TYPE];
    if (![actionItemType isKindOfClass:NSString.class]) {
      NSString *description = [NSString stringWithFormat:@"The %@ property is mandatory to set for '%@' action item", FB_ACTION_ITEM_KEY_TYPE, actionItem];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    
    Class gestureItemClass = [gestureItemsMapping objectForKey:actionItemType];
    if (nil == gestureItemClass) {
      NSString *description = [NSString stringWithFormat:@"'%@' action item type '%@' is not supported. Only the following action item types are supported: %@", actionId, actionItemType, supportedActionItemTypes];
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    
    FBW3CGestureItem *gestureItem = [[gestureItemClass alloc] initWithActionItem:actionItem application:self.application previousItem:[chain.items lastObject] offset:chain.durationOffset error:error];
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
  XCSynthesizedEventRecord *eventRecord = [[XCSynthesizedEventRecord alloc] initWithName:@"W3C Touch Action" interfaceOrientation:orientation];
  NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *actionsMapping = [NSMutableDictionary new];
  NSMutableArray<NSString *> *actionIds = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *action in self.actions) {
    id actionId = [action objectForKey:FB_KEY_ID];
    if (![actionId isKindOfClass:NSString.class] || 0 == [actionId length]) {
      if (error) {
        NSString *description = [NSString stringWithFormat:@"The mandatory action %@ field is missing or empty for '%@'", FB_KEY_ID, action];
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    if (nil != [actionsMapping objectForKey:actionId]) {
      if (error) {
        NSString *description = [NSString stringWithFormat:@"Action %@ '%@' is not unique for '%@'", FB_KEY_ID, actionId, action];
        *error = [[FBErrorBuilder.builder withDescription:description] build];
      }
      return nil;
    }
    [actionIds addObject:actionId];
    [actionsMapping setObject:action forKey:actionId];
  }
  for (NSString *actionId in actionIds.copy) {
    NSDictionary<NSString *, id> *actionDescription = [actionsMapping objectForKey:actionId];
    XCPointerEventPath *eventPath = [self eventPathWithActionDescription:actionDescription forActionId:actionId error:error];
    if (nil == eventPath) {
      return nil;
    }
    [eventRecord addPointerEventPath:eventPath];
  }
  return eventRecord;
}

@end
