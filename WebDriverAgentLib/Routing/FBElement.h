/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Protocol that should be implemented by class that can return element properties defined in WebDriver Spec
 */
@protocol FBElement <NSObject>

/*! Element's frame in CGRect format */
@property (nonatomic, readonly, assign) CGRect wdFrame;

/*! Element's frame in NSDictionary format */
@property (nonatomic, readonly, copy) NSDictionary *wdRect;

/*! Element's name */
@property (nonatomic, readonly, copy) NSString *wdName;

/*! Element's label */
@property (nonatomic, readonly, copy) NSString *wdLabel;

/*! Element's type */
@property (nonatomic, readonly, copy) NSString *wdType;

/*! Element's value */
@property (nonatomic, readonly, strong, nullable) id wdValue;

/*! Whether element is enabled */
@property (nonatomic, readonly, getter = isWDEnabled) BOOL wdEnabled;

/*! Whether element is visible */
@property (nonatomic, readonly, getter = isWDVisible) BOOL wdVisible;

/*! Whether element is accessible */
@property (nonatomic, readonly, getter = isWDAccessible) BOOL wdAccessible;

/*! Whether element is an accessibility container (contains children of any depth that are accessible) */
@property (nonatomic, readonly, getter = isWDAccessibilityContainer) BOOL wdAccessibilityContainer;

/**
 Returns value of given property specified in WebDriver Spec
 Check the FBElement protocol to get list of supported attributes.
 This method also supports shortcuts, like wdName == name, wdValue == value.
 
 @param name WebDriver Spec property name
 @return the corresponding property value
 @throws FBUnknownAttributeException if there is no matching attribute defined in FBElement protocol
 */
- (nullable id)fb_valueForWDAttributeName:(NSString *__nullable)name;

@end

NS_ASSUME_NONNULL_END
