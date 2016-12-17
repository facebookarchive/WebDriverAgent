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

NS_ASSUME_NONNULL_END
