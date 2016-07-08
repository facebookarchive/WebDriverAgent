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
 Helper class used to create xpath string
 */
@interface FBXPathCreator : NSObject

/**
 Creates xpath string for elements containing elements of type elementType

 @param elementType requested XCUIElementType of sub-elements
 @return A string representing the xpath element
 */
+ (NSString *)xpathWithSubelementsOfType:(XCUIElementType)elementType;

@end

NS_ASSUME_NONNULL_END
