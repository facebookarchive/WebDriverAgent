/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/FBApplication.h>

@interface FBSpringboardApplication : FBApplication

/**
 @return FBApplication that is attached to SpringBoard
 */
+ (instancetype)springboard;

/**
 Taps application on SpringBoard app with given identifer

 @param identifier identifier of the application to tap
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)fb_tapApplicationWithIdentifier:(NSString *)identifier error:(NSError **)error;

@end
