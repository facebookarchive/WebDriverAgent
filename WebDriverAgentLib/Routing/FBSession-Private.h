/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/FBSession.h>

@class FBElementCache;

NS_ASSUME_NONNULL_BEGIN

@interface FBSession ()
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) FBElementCache *elementCache;

/**
 Sets session as current session
 */
+ (void)markSessionActive:(FBSession *)session;

@end

NS_ASSUME_NONNULL_END
