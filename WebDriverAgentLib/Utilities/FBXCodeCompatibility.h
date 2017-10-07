/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/WebDriverAgentLib.h>

/**
 Set of categories that patches method name differences between Xcode versions,
 so that WDA can be build with different Xcode versions.
 */
@interface XCElementSnapshot (FBCompatibility)

- (XCElementSnapshot *)fb_rootElement;

@end

/**
 The exception happends if one tries to call application method,
 which is not supported in the current iOS version
 */
extern NSString *const FBApplicationMethodNotSupportedException;

@interface XCUIApplication (FBCompatibility)

+ (instancetype)fb_applicationWithPID:(pid_t)processID;

- (NSUInteger)fb_state;

- (void)fb_activate;

+ (BOOL)fb_hasMultiAppSupport;

@end
