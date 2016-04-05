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

NSString *wdAttributeNameForAttributeName(NSString *name);

@protocol FBElement <NSObject>

@property (readonly, assign) CGRect wdFrame;
@property (readonly, copy) NSDictionary *wdRect;
@property (readonly, copy) NSDictionary *wdSize;
@property (readonly, copy) NSDictionary *wdLocation;
@property (readonly, copy) NSString *wdName;
@property (readonly, copy) NSString *wdLabel;
@property (readonly, copy) NSString *wdType;
@property (readonly, strong) id wdValue;
@property (readonly, getter = isWDEnabled) BOOL wdEnabled;
@property (atomic, readonly, getter = isWDVisible) BOOL wdVisible;
@property (atomic, readonly, getter = isWDAccessible) BOOL wdAccessible;

- (id)valueForWDAttributeName:(NSString *)name;

@end
