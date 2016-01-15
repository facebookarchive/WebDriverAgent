/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

typedef BOOL (^LogCallback)(NSDictionary *data);

@protocol UIATargetDelegate

- (BOOL)logWithInfo:(NSDictionary *)info;

@end

@interface FBAutomationTargetDelegate : NSObject <UIATargetDelegate>

// If set to something, logWithInfo will call the callback
// with the info
@property (strong, nonatomic) LogCallback callback;

+ (FBAutomationTargetDelegate *)delegateWithLogCallback:(LogCallback)callback;

@end
