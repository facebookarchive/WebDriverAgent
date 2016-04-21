/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCEventGenerator+SyncEvents.h"

#import "FBWDALogger.h"

static const CGFloat FBTapDuration = 0.5;

@implementation XCEventGenerator (SyncEvents)

- (BOOL)fb_syncTapAtPoint:(CGPoint)point orientation:(UIInterfaceOrientation)orientation error:(NSError **)error
{
  __block BOOL didSuccess;
  __block BOOL isWaiting = YES;
  [[XCEventGenerator sharedGenerator] pressAtPoint:point forDuration:FBTapDuration orientation:orientation handler:^(NSError *commandError) {
    if (commandError) {
      [FBWDALogger logFmt:@"Failed to perform tap: %@", commandError];
    }
    if (error) {
      *error = commandError;
    }
    didSuccess = (commandError == nil);
    isWaiting = NO;
  }];
  while (isWaiting) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  return didSuccess;
}
@end
