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

NS_ASSUME_NONNULL_BEGIN

/**
 Class used to translate between XCUIElementType and string name
 */
@interface FBElementTypeTransformer : NSObject

/**
 Converts string to XCUIElementType

 @param typeName converted string to XCUIElementType
 @return Proper XCUIElementType or XCUIElementTypeAny if typeName is nil or unrecognised
 */
+ (XCUIElementType)elementTypeWithTypeName:(NSString *__nullable)typeName;

/**
 Converts XCUIElementType to string

 @param type converted XCUIElementType to string
 @return XCUIElementType as NSString
 */
+ (NSString *)stringWithElementType:(XCUIElementType)type;

/**
 Converts XCUIElementType to short string by striping `XCUIElementType` from it

 @param type converted XCUIElementType to string
 @return XCUIElementType as NSString with stripped `XCUIElementType`
 */
+ (NSString *)shortStringWithElementType:(XCUIElementType)type;

@end

NS_ASSUME_NONNULL_END
