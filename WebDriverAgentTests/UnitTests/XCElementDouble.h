/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import "FBElement.h"
#import <XCTest/XCUIElementTypes.h>

@interface XCElementDouble : NSObject<FBElement>
@property (nonatomic, readwrite, copy, nonnull) NSDictionary *wdRect;
@property (nonatomic, readwrite, assign) CGRect wdFrame;
@property (nonatomic, copy, readwrite, nullable) NSString *wdName;
@property (nonatomic, copy, readwrite, nullable) NSString *wdLabel;
@property (nonatomic, copy, readwrite, nonnull) NSString *wdType;
@property (nonatomic, strong, readwrite, nullable) id wdValue;
@property (nonatomic, readwrite, getter=isWDEnabled) BOOL wdEnabled;
@property (nonatomic, readwrite, getter=isWDVisible) BOOL wdVisible;
@property (nonatomic, readwrite, getter=isWDAccessible) BOOL wdAccessible;
@property (nonatomic, copy, readwrite, nullable) NSArray *children;
@property (nonatomic, readwrite, assign) XCUIElementType elementType;
@property (nonatomic, readwrite, getter=isWDAccessibilityContainer) BOOL wdAccessibilityContainer;
@end
