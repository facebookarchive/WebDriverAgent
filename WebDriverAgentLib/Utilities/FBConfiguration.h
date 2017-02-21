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

/*! Notification used to notify about unknown setting name */
extern NSString *const FBUnknownSettingNameException;

/**
 Accessors for Global Constants.
 */
@interface FBConfiguration : NSObject

/*! Whether to add @visible attribute to UI XML representation. Default value is NO */
@property (atomic) BOOL showVisibilityAttributeForXML;

/*! Whether to use alternative visibility detection. Default value is NO */
@property (atomic) BOOL useAlternativeVisibilityDetection;

/**
 Returns a singleton object for the current class
 */
+ (instancetype)sharedInstance;

/**
 Reset all setting properties to their default values.
 This method is automatically invoked upon new session initialization,
 so all the settings are always set to their default values for each testing session.
 */
- (void)resetSettings;

/**
 Change values of existing instance properties
 
 @param newValues Dictionary containing new property values.
                  Dictionary keys should be valid property names.
 @throws FBUnknownSettingException If there is no such property with given name
 */
- (void)changeSettings:(NSDictionary<NSString *, id> *)newValues;

/**
 Returns values of existing instance properties
 
 @return Dictionary containing valid property names as keys and
         corresponding property values
 */
- (NSDictionary<NSString *, id> *)currentSettings;

/**
 Switch for enabling/disabling reporting fake collection view cells by Accessibility framework.
 If set to YES it will report also invisible cells.
 */
+ (void)shouldShowFakeCollectionViewCells:(BOOL)showFakeCells;

/**
 The range of ports that the HTTP Server should attempt to bind on launch
 */
+ (NSRange)bindingPortRange;

/**
 YES if should listen on USB. NO otherwise.
 */
+ (BOOL)shouldListenOnUSB;

/**
 YES if verbose logging is enabled. NO otherwise.
 */
+ (BOOL)verboseLoggingEnabled;

@end

NS_ASSUME_NONNULL_END
