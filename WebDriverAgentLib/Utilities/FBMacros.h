/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

// Typedef to help with storing constant strings for enums.
#if __has_feature(objc_arc)
    typedef __unsafe_unretained NSString* FBLiteralString;
#else
    typedef NSString* FBLiteralString;
#endif

/*! Returns 'value' or nil if 'value' is an empty string */
#define FBTransferEmptyStringToNil(value) ([value isEqual:@""] ? nil : value)

/*! Returns 'value1' or 'value2' if 'value1' is an empty string */
#define FBFirstNonEmptyValue(value1, value2) ^{ \
  id value1computed = value1; \
  return (value1computed == nil || [value1computed isEqual:@""] ? value2 : value1computed); \
}()

/*! Returns 'value' or NSNull if 'value' is nil */
#define FBValueOrNull(value) ((value) ?: [NSNull null])

/*!
  Returns name of class property as a string
  previously used [class new] errors out on certain classes because new will be declared unavailable
  Instead we are casting into a class to get compiler support with property name.
*/
#define FBStringify(class, property) ({if(NO){[((class *)nil) property];} @#property;})

/*! Creates weak type for given 'arg' */
#define FBWeakify(arg) typeof(arg) __weak wda_weak_##arg = arg

/*! Creates strong type for FBWeakify-ed 'arg' */
#define FBStrongify(arg) \
  _Pragma("clang diagnostic push") \
  _Pragma("clang diagnostic ignored \"-Wshadow\"") \
  typeof(arg) arg = wda_weak_##arg \
  _Pragma("clang diagnostic pop")

/*! Returns YES if current system version satisfies the given codition */
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/*! Converts the given number of milliseconds into seconds */
#define FBMillisToSeconds(ms) ((ms) / 1000.0)
