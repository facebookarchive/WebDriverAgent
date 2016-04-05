/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

/**
 Accessors for Global Constants.
 */
@interface FBWDAConstants : NSObject

/**
 YES if running on an iOS 9-or-greater Host, NO otherwise
 */
+ (BOOL)isIOS9OrGreater;

/**
 The range of ports that the HTTP Server should attempt to bind on launch
 */
+ (NSRange)bindingPortRange;

/**
 YES if verbose logging is enabled. NO otherwise.
 */
+ (BOOL)verboseLoggingEnabled;

@end
