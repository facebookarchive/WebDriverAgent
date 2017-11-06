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
 Returns array of classes that conforms to given protocol
 */
NSArray<Class> *FBClassesThatConformsToProtocol(Protocol *protocol);

/**
 Method used to retrieve pointer for given symbol 'name' from given 'binary'

 @param binary path to binary we want to retrieve symbols pointer from
 @param name name of the symbol
 @return pointer to symbol
 */
void *FBRetrieveSymbolFromBinary(const char *binary, const char *name);

/**
 Get the compiler SDK version as string.

 @return SDK version as string, for example "10.0" or nil if it cannot be received
 */
NSString * _Nullable FBSDKVersion(void);

/**
 Check if the compiler SDK version is less than the given version.
 The current iOS version is taken instead if SDK version cannot be retrieved.

 @param expected the expected version to compare with, for example '10.3'
 @return YES if the given version is less than the SDK version used for WDA compilation
 */
BOOL isSDKVersionLessThan(NSString *expected);

/**
 Check if the compiler SDK version is less or equal to the given version.
 The current iOS version is taken instead if SDK version cannot be retrieved.

 @param expected the expected version to compare with, for example '10.3'
 @return YES if the given version is less or equal to the SDK version used for WDA compilation
 */
BOOL isSDKVersionLessThanOrEqualTo(NSString *expected);

/**
 Check if the compiler SDK version is equal to the given version.
 The current iOS version is taken instead if SDK version cannot be retrieved.

 @param expected the expected version to compare with, for example '10.3'
 @return YES if the given version is equal to the SDK version used for WDA compilation
 */
BOOL isSDKVersionEqualTo(NSString *expected);

/**
 Check if the compiler SDK version is greater or equal to the given version.
 The current iOS version is taken instead if SDK version cannot be retrieved.

 @param expected the expected version to compare with, for example '10.3'
 @return YES if the given version is greater or equal to the SDK version used for WDA compilation
 */
BOOL isSDKVersionGreaterThanOrEqualTo(NSString *expected);

/**
 Check if the compiler SDK version is greater than the given version.
 The current iOS version is taken instead if SDK version cannot be retrieved.

 @param expected the expected version to compare with, for example '10.3'
 @return YES if the given version is greater than the SDK version used for WDA compilation
 */
BOOL isSDKVersionGreaterThan(NSString *expected);

NS_ASSUME_NONNULL_END
