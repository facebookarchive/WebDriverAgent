/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "FBCommandHandler.h"

@class UIAElement;

@interface FBFindElementCommands : NSObject <FBCommandHandler>

+ (UIAElement *)elementUsing:(NSString *)usingText withValue:(NSString *)value;

+ (NSArray *)elementsUsing:(NSString *)usingText withValue:(NSString *)value;

+ (UIAElement *)elementOfClassOnSimulator:(NSString *)UIAutomationClassName;

+ (NSArray *)elementsOfClassOnSimulator:(NSString *)UIAutomationClassName;

+ (BOOL)isElement:(UIAElement *)element underElement:(UIAElement *)parentElement;

@end
