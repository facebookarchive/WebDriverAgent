/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBUIAppDelegate.h"

int main(int argc, char * argv[])
{
  NSLog(@"Host:%@\nEnv:%@\nArgs:%@",
        [[NSProcessInfo processInfo] hostName],
        [[NSProcessInfo processInfo] environment],
        [[NSProcessInfo processInfo] arguments]
        );
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([FBUIAppDelegate class]));
  }
}
