/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBBaseActionsSynthesizer.h"

#import "FBErrorBuilder.h"

@implementation FBBaseActionsSynthesizer

- (instancetype)initWithActions:(NSArray *)actions forApplication:(XCUIApplication *)application
{
  self = [super init];
  if (self) {
    _actions = actions;
    _application = application;
  }
  return self;
}

- (nullable XCSynthesizedEventRecord *)synthesizeWithError:(NSError **)error
{
  @throw [[FBErrorBuilder.builder withDescription:@"Override this method in subclasses"] build];
  return nil;
}

@end
