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

/**
 Builder used create error raised by WebDriverAgent
 */
@interface FBErrorBuilder : NSObject

/**
 Default constructor
 */
+ (instancetype)builder;

/**
 Configures description set as NSLocalizedDescriptionKey

 @param description set as NSLocalizedDescriptionKey
 @return builder instance
 */
- (instancetype)withDescription:(NSString *)description;

/**
 Configures description set as NSLocalizedDescriptionKey with convenient format

 @param format of description set as NSLocalizedDescriptionKey
 @return builder instance
 */
- (instancetype)withDescriptionFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/**
 Configures error set as NSUnderlyingErrorKey

 @param innerError used to set NSUnderlyingErrorKey
 @return builder instance
 */
- (instancetype)withInnerError:(NSError *)innerError;

/**
 Builder used create error raised by WebDriverAgent

 @return built error
 */
- (NSError *)build;

/**
 Builder used create error raised by WebDriverAgent

 @param error pointer used to return built error
 @return fixed NO to apply to Apple's coding conventions
 */
- (BOOL)buildError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
