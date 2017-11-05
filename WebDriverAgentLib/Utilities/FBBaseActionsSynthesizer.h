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
 
 @param eventPath The destination XCPointerEventPath instance
 @param index The index of the current gesture in the chain. Starts from zero
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return YES if the gesture has been successully added to the XCPointerEventPath instance
 */
- (BOOL)addToEventPath:(XCPointerEventPath*)eventPath index:(NSUInteger)index error:(NSError **)error;

/**
 Increase duration of the current gesture.
 
 @param value The duration value to add in milliseconds
 @return YES if the gesture supports duration increment
 */
- (BOOL)increaseDuration:(double)value;

/**
 Calculate absolute gesture position on the screen based on provided element and positionOffset values.
 
 @param element The element instance to perform the gesture on. If element equals to nil then positionOffset is considered as absolute coordinates
 @param positionOffset The actual coordinate offset. If this calue equals to nil then element's hitpoint is taken as gesture position. If element is not nil then this offset is calculated relatively to the top-left cordner of the element's position
 @return Adbsolute gesture position on the screen
 */
- (CGPoint)hitpointWithElement:(nullable XCUIElement *)element positionOffset:(nullable NSValue *)positionOffset;

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
 @return The constructed XCPointerEventPath instance or nil if there was a failure
 */
- (nullable XCPointerEventPath *)asEventPathWithError:(NSError **)error;

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
