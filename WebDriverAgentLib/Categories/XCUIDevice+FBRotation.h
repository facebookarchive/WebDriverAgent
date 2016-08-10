/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import "FBApplication.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCUIDevice (FBRotation)

/**
 Sets the devices orientation to the rotation passed.
 
 @param rotationObj The rotation defining the devices orientation.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)setDeviceRotation:(NSDictionary *)rotationObj;

/*! The UIDeviceOrientation to rotation mappings */
@property (strong, nonatomic, readonly) NSDictionary *rotationMapping;

@end

NS_ASSUME_NONNULL_END
