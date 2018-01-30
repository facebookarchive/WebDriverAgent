/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementCache.h"
#import "XCUIApplication.h"
#import "XCElementSnapshot.h"
#import "XCSynthesizedEventRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBBaseGestureItem : NSObject

/*! Raw JSON representation of the corresponding action item */
@property (nonatomic) NSDictionary<NSString *, id> *actionItem;
/*! Current application instance */
@property (nonatomic) XCUIApplication *application;
/*! Absolute position on the screen where the gesure should be performed */
@property (nonatomic) CGPoint atPosition;
/*! Gesture duration in milliseconds */
@property (nonatomic) double duration;
/*! Gesture offset in the chain in milliseconds */
@property (nonatomic) double offset;

/**
 Get the name of the corresponding raw action item. This method is expected to be overriden in subclasses.
 
 @return The corresponding action item key in object's raw JSON reprsentation
 */
+ (NSString *)actionName;

/**
 Add the current gesture to XCPointerEventPath instance. This method is expected to be overriden in subclasses.
 
 @param eventPath The destination XCPointerEventPath instance. If nil value is passed then a new XCPointerEventPath instance is going to be created
 @param allItems The existing actions chain to be transformed into event path
 @param currentItemIndex The index of the current item in allItems array
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return the constructed XCPointerEventPath instance or nil in case of failure
 */
- (nullable NSArray<XCPointerEventPath *> *)addToEventPath:(nullable XCPointerEventPath *)eventPath allItems:(NSArray<FBBaseGestureItem *> *)allItems currentItemIndex:(NSUInteger)currentItemIndex error:(NSError **)error;

/**
 Returns fixed hit point coordinates for the case when XCTest fails to transform element snaapshot properly on screen rotation.
 
 @param hitPoint The initial hitpoint coordinates
 @param snapshot Element's snapshot instance
 @return The fixed hit point coordinates, if there is a need to fix them, or the unchanged hit point value
 */
- (CGPoint)fixedHitPointWith:(CGPoint)hitPoint forSnapshot:(XCElementSnapshot *)snapshot;

/**
 Calculate absolute gesture position on the screen based on provided element and positionOffset values.
 
 @param element The element instance to perform the gesture on. If element equals to nil then positionOffset is considered as absolute coordinates
 @param positionOffset The actual coordinate offset. If this calue equals to nil then element's hitpoint is taken as gesture position. If element is not nil then this offset is calculated relatively to the top-left cordner of the element's position
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return Adbsolute gesture position on the screen or nil if the calculation fails (for example, the element is invisible)
 */
- (nullable NSValue *)hitpointWithElement:(nullable XCUIElement *)element positionOffset:(nullable NSValue *)positionOffset error:(NSError **)error;

@end


@interface FBBaseGestureItemsChain : NSObject

/*! All gesture items collected in the chain */
@property (readonly, nonatomic) NSMutableArray<FBBaseGestureItem *> *items;
/*! Total length of all the gestures in the chain in milliseconds */
@property (nonatomic) double durationOffset;

/**
 Add a new gesture item to the current chain. The method is expected to be overriden in subclasses.
 
 @param item The actual gesture instance to be added
 */
- (void)addItem:(FBBaseGestureItem *)item;

/**
 Represents the chain as XCPointerEventPath instance.
 
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return The constructed array of XCPointerEventPath instances or nil if there was a failure
 */
- (nullable NSArray<XCPointerEventPath *> *)asEventPathsWithError:(NSError **)error;

@end


@interface FBBaseActionsSynthesizer : NSObject

/*! Raw actions chain received from request's JSON */
@property (readonly, nonatomic) NSArray *actions;
/*! Current application instance */
@property (readonly, nonatomic) XCUIApplication *application;
/*! Current elements cache */
@property (readonly, nonatomic, nullable) FBElementCache *elementCache;

/**
 Initializes actions synthesizer. This initializer should be used only by subclasses.
 
 @param actions The raw actions chain received from request's JSON. The format of this chain is defined by the standard, implemented in the correspoding subclass.
 @param application Current application instance
 @param elementCache Elements cache, which is used to replace elements references in the chain with their instances. We assume the chain already contains element instances if this parameter is set to nil
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return The corresponding synthesizer instance or nil in case of failure (for example if `actions` is nil or empty)
 */
- (nullable instancetype)initWithActions:(NSArray *)actions forApplication:(XCUIApplication *)application elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error;

/**
 Synthesizes XCTest-compatible event record to be performed in the UI. This method is supposed to be overriden by subclasses.
 
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return The generated event record or nil in case of failure
 */
- (nullable XCSynthesizedEventRecord *)synthesizeWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
