/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

// Convenience macro to make sure that we're running on the main thread.
#define FBWDAAssertMainThread() NSAssert([NSThread isMainThread], @"This method must be called on the main thread")

// Typedef to help with storing constant strings for enums.
#if __has_feature(objc_arc)
    typedef __unsafe_unretained NSString* FBWDALiteralString;
#else
    typedef NSString* FBWDALiteralString;
#endif
