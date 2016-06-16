/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (IBAction)showAlert:(id)sender
{
  UIAlertController *alerController =
  [UIAlertController alertControllerWithTitle:@"Magic"
                                      message:@"Should read"
                               preferredStyle:UIAlertControllerStyleAlert];
  [alerController addAction:[UIAlertAction actionWithTitle:@"Will do" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alerController animated:YES completion:nil];
}

- (IBAction)deadlockApp:(id)sender
{
  dispatch_sync(dispatch_get_main_queue(), ^{
    // This will never execute
  });
}

@end
