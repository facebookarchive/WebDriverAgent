/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBElementCache;
@class XCUIApplication;

@interface FBSession : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) XCUIApplication *application;
@property (nonatomic, strong, readonly) FBElementCache *elementCache;

/**
 @return list of active sessions
 */
+ (NSArray *)activeSessions;

/**
 Creates and saves new session for application

 @param application The application that we want to create session for
 @return new session
 */
+ (instancetype)sessionWithXCUIApplication:(XCUIApplication *)application;

/**
 Fetches session for given identifier.

 @param identifier Identifer for searched session
 @return session. Can return nil if session does not exists
 */
+ (instancetype)sessionWithIdentifier:(NSString *)identifier;

/**
 Kills application associated with that session and removes session
 */
- (void)kill;


@end
