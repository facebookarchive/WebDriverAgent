/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCUIElementTypes.h>

@interface FBElementTypeTransformer : NSObject

+ (XCUIElementType)elementTypeWithTypeName:(NSString *)typeName;

+ (NSString *)stringWithElementType:(XCUIElementType)type;

+ (NSString *)shortStringWithElementType:(XCUIElementType)type;

@end
