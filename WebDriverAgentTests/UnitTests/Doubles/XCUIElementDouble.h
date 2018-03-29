/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <WebDriverAgentLib/FBElement.h>
#import <XCTest/XCUIElementTypes.h>

@class XCUIApplication;

@interface XCUIElementDouble : NSObject<FBElement>
@property (nonatomic, strong, nonnull) XCUIApplication *application;
@property (nonatomic, readwrite, assign) CGRect frame;
@property (nonatomic, assign) BOOL fb_isObstructedByAlert;
@property (nonatomic, readwrite, copy, nonnull) NSDictionary *wdRect;
@property (nonatomic, readwrite, assign) CGRect wdFrame;
@property (nonatomic, readwrite, copy, nonnull) NSString *wdUID;
@property (nonatomic, copy, readwrite, nullable) NSString *wdName;
@property (nonatomic, copy, readwrite, nullable) NSString *wdLabel;
@property (nonatomic, copy, readwrite, nonnull) NSString *wdType;
@property (nonatomic, strong, readwrite, nullable) NSString *wdValue;
@property (nonatomic, readwrite, getter=isWDEnabled) BOOL wdEnabled;
@property (nonatomic, readwrite, getter=isWDVisible) BOOL wdVisible;
@property (nonatomic, readwrite, getter=isWDAccessible) BOOL wdAccessible;
@property (copy, nonnull) NSArray *children;
@property (nonatomic, readwrite, assign) XCUIElementType elementType;
@property (nonatomic, readwrite, getter=isWDAccessibilityContainer) BOOL wdAccessibilityContainer;

- (void)resolve;

// Checks
@property (nonatomic, assign, readonly) BOOL didResolve;

@end
