/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/FBElementHitPoint.h>
#import <WebDriverAgentLib/XCElementSnapshot.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCElementSnapshot (FBHitPoint)

/**
 Wrapper for Apple's hitpoint, thats resolves few known issues
 */
- (nullable FBElementHitPoint *)fb_hitPoint:(NSError **)error;

/**
 Wrapper for Apple's hitpoint, thats resolves few known issues
 and will try provide alternatives in case of failure
 */
- (nullable FBElementHitPoint *)fb_hitPointWithAlternativeOnFailure:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
