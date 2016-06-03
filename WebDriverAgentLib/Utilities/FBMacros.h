/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

// Convenience macro to make sure that we're running on the main thread.
#define FBAssertMainThread() NSAssert([NSThread isMainThread], @"This method must be called on the main thread")

// Typedef to help with storing constant strings for enums.
#if __has_feature(objc_arc)
    typedef __unsafe_unretained NSString* FBLiteralString;
#else
    typedef NSString* FBLiteralString;
#endif

#define FBTransferEmptyStringToNil(value) ([value isEqual:@""] ? nil : value)
#define FBFirstNonEmptyValue(value1, value2) ([value1 isEqual:@""] ? value2 : value1)
#define FBValueOrNull(value) ((value) ?: [NSNull null])
#define FBStringify(class, property) ({if(NO){[class.new property];} @#property;})

#define FBWeakify(arg) typeof(arg) __weak wda_weak_##arg = arg
#define FBStrongify(arg) \
  _Pragma("clang diagnostic push") \
  _Pragma("clang diagnostic ignored \"-Wshadow\"") \
  typeof(arg) arg = wda_weak_##arg \
  _Pragma("clang diagnostic pop")