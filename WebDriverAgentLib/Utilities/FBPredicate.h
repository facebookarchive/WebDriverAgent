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
 HACK!!!
 This is hacky predicate that will force XCTest to evaluate whole XCElementSnapshot.
 Of course we should aim not to use this, but it buys us some time.
*/
@interface FBPredicate : NSPredicate

+ (NSPredicate *)predicateWithFormat:(NSString *)predicateFormat,  ...;

/*! Predicate string attached to original predicate to force resolve it in XCTest */
+ (NSString *)forceResolvePredicateString;

@end

NS_ASSUME_NONNULL_END
