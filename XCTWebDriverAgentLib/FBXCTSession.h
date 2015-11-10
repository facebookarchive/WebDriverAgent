/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <XCTWebDriverAgentLib/FBSession.h>
#import <XCTWebDriverAgentLib/XCUIApplication.h>

@interface FBXCTSession : FBSession
@property (nonatomic, strong, readonly) XCUIApplication *application;

/**
 Creates and saves new session for application
 
 @param application The application that we want to create session for
 @return new session
 */
+ (instancetype)sessionWithXCUIApplication:(XCUIApplication *)application;

@end
