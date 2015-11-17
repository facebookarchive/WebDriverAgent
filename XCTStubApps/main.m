/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import "FBUIAppDelegate.h"

int main(int argc, char * argv[])
{
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([FBUIAppDelegate class]));
  }
}

#else

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
  return NSApplicationMain(argc, argv);
}

#endif
