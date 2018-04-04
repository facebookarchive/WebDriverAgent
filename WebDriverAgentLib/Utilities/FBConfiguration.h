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
 Accessors for Global Constants.
 */
@interface FBConfiguration : NSObject

/*! If set to YES will ask TestManagerDaemon for element visibility */
+ (void)setShouldUseTestManagerForVisibilityDetection:(BOOL)value;
+ (BOOL)shouldUseTestManagerForVisibilityDetection;

/*! If set to YES will use compact (standards-compliant) & faster responses */
+ (void)setShouldUseCompactResponses:(BOOL)value;
+ (BOOL)shouldUseCompactResponses;

/*! If shouldUseCompactResponses == NO, is the comma-separated list of fields to return with each element. Defaults to "type,label". */
+ (void)setElementResponseAttributes:(NSString *)value;
+ (NSString *)elementResponseAttributes;

/*! Disables remote query evaluation making Xcode 9.x tests behave same as Xcode 8.x test */
+ (void)disableRemoteQueryEvaluation;

/*! Disables attribute key path analysis, which will cause XCTest on Xcode 9.x to ignore some elements */
+ (void)disableAttributeKeyPathAnalysis;

/* The maximum typing frequency for all typing activities */
+ (void)setMaxTypingFrequency:(NSUInteger)value;
+ (NSUInteger)maxTypingFrequency;

/* Use singleton test manager proxy */
+ (void)setShouldUseSingletonTestManager:(BOOL)value;
+ (BOOL)shouldUseSingletonTestManager;

/**
 The range of ports that the HTTP Server should attempt to bind on launch
 */
+ (NSRange)bindingPortRange;

/**
 YES if verbose logging is enabled. NO otherwise.
 */
+ (BOOL)verboseLoggingEnabled;

@end

NS_ASSUME_NONNULL_END
