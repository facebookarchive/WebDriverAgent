/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@interface FBWebDriverAgent : NSObject

/**
 Starts WebDriverAgent service by booting HTTP and USB server
 */
- (void)start;

/**
 Method that should be used to notify WebDriverAgent about XCTest framework failure

 @param failureDescription description of the failure
 */
- (void)handleTestFailureWithDescription:(NSString *)failureDescription;

@end
