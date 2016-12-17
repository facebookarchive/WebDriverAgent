/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/FBRouteRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBRouteRequest ()
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, copy, readwrite) NSDictionary *parameters;
@property (nonatomic, copy, readwrite) NSDictionary *arguments;
@property (nonatomic, strong, readwrite) FBSession *session;
@end

NS_ASSUME_NONNULL_END
