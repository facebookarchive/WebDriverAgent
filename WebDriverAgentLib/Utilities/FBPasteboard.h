/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBPasteboard : NSObject

/**
 Sets data to the general pasteboard

 @param data base64-encoded string containing the data chunk which is going to be written to the pasteboard
 @param type one of the possible data types to set: plaintext, url, image
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return YES if the operation was successful
 */
+ (BOOL)setData:(NSData *)data forType:(NSString *)type error:(NSError **)error;

/**
 Gets the data contained in the general pasteboard

 @param type one of the possible data types to get: plaintext, url, image
 @param error If there is an error, upon return contains an NSError object that describes the problem
 @return NSData object, containing the pasteboard content or an empty string if the pasteboard is empty.
 nil is returned if there was an error while getting the data from the pasteboard
 */
+ (nullable NSData *)dataForType:(NSString *)type error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

