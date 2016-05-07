/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAutomationTargetDelegate.h"

const NSString *kUIALoggingKeyElementInfo = @"kUIALoggingKeyElementInfo";

@implementation FBAutomationTargetDelegate

+ (FBAutomationTargetDelegate *)delegateWithLogCallback:(LogCallback)cb
{
    FBAutomationTargetDelegate *delegate = [[FBAutomationTargetDelegate alloc] init];
    delegate.callback = cb;
    return delegate;
}

- (BOOL)logWithInfo:(NSDictionary *)info
{
  // Each element is a dictionary with keys:
  // className: e.g. UIAScrollView
  // convertedRect: CGRect in string
  // elements: array of child elements (optional)
  // name: a11y name
  // value: a11y value (optional)
  //NSDictionary *elementInfo = info[kUIALoggingKeyElementInfo];

    if (_callback) {
        return _callback(info);
    }
    return YES;
}

@end
