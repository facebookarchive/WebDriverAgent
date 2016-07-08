/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^FBRunLoopSpinnerBlock)();
typedef __nullable id (^FBRunLoopSpinnerObjectBlock)();

@interface FBRunLoopSpinner : NSObject

/**
 Dispatches block and spins the run loop until `completion` block is called.

 @param block the block to wait for to finish.
 */
+ (void)spinUntilCompletion:(void (^)(void(^completion)()))block;

/**
 Updates the error message to print in the event of a timeout.

 @param timeoutErrorMessage the Error Message to print.
 @return the receiver, for chaining.
 */
- (instancetype)timeoutErrorMessage:(NSString *)timeoutErrorMessage;

/**
 Updates the timeout of the receiver.

 @param timeout the amount of time to wait before timing out.
 @return the receiver, for chaining.
 */
- (instancetype)timeout:(NSTimeInterval)timeout;

/**
 Updates the interval of the receiver.

 @param interval the amount of time to wait before checking condition again.
 @return the receiver, for chaining.
 */
- (instancetype)interval:(NSTimeInterval)interval;

/**
 Spins the Run Loop until `untilTrue` returns YES or a timeout is reached.

 @param untilTrue the condition to meet.
 @return YES if the condition was met, NO if the timeout was reached first.
 */
- (BOOL)spinUntilTrue:(FBRunLoopSpinnerBlock)untilTrue;

/**
 Spins the Run Loop until `untilTrue` returns YES or a timeout is reached.

 @param untilTrue the condition to meet.
 @param error to fill in case of timeout.
 @return YES if the condition was met, NO if the timeout was reached first.
 */
- (BOOL)spinUntilTrue:(FBRunLoopSpinnerBlock)untilTrue error:(NSError **)error;

/**
 Spins the Run Loop until `untilNotNil` returns non nil value or a timeout is reached.

 @param untilNotNil the condition to meet.
 @param error to fill in case of timeout.
 @return YES if the condition was met, NO if the timeout was reached first.
 */
- (nullable id)spinUntilNotNil:(FBRunLoopSpinnerObjectBlock)untilNotNil error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
