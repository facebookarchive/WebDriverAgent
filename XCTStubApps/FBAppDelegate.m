/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAppDelegate.h"

@interface FBAppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end

@implementation FBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.window = [NSWindow new];
  self.window.backgroundColor = [NSColor blueColor];
  self.window.contentViewController = [NSViewController new];
}

@end
