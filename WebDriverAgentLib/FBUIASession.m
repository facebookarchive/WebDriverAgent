/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBUIASession.h"

#import "FBSession-Private.h"
#import "FBUIAElementCache.h"

@implementation FBUIASession

+ (instancetype)newSessionWithIdentifier:(NSString *)identifier
{
  FBUIASession *session = [FBUIASession new];
  session.identifier = identifier;
  session.elementCache = [FBUIAElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

@end
