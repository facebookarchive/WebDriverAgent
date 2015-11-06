/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>

@protocol FBElement <NSObject>

@property (readonly, assign) CGRect frame;
@property (readonly, copy) NSDictionary *rect;
@property (readonly, copy) NSString *name;
@property (readonly, copy) NSString *label;
@property (readonly, copy) NSString *type;
@property (readonly, strong) id value;
@property (readonly, getter = isEnabled) BOOL enabled;
@property (readonly, getter = isVisible) BOOL visible;

@end