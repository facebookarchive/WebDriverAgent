/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <WebDriverAgentLib/FBResponsePayload.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Class that represents WebDriverAgent JSON repsonse
 */
@interface FBResponseJSONPayload : NSObject <FBResponsePayload>

/**
 Initializer for JSON respond that converts given 'dictionary' to JSON
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
