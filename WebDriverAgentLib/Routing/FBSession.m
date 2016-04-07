/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSession.h"
#import "FBSession-Private.h"

#import <objc/runtime.h>

#import "FBApplication.h"
#import "FBElementCache.h"
#import "XCAccessibilityElement.h"
#import "XCAXClient_iOS.h"
#import "XCUIElement.h"

NSString *const FBApplicationCrashedException = @"FBApplicationCrashedException";

@interface FBSession ()
@property (nonatomic, strong, readwrite) FBApplication *testedApplication;
@end

@implementation FBSession

static FBSession *_activeSession;
+ (instancetype)activeSession
{
  return _activeSession;
}

+ (void)markSessionActive:(FBSession *)session
{
  _activeSession = session;
}

+ (instancetype)sessionWithIdentifier:(NSString *)identifier
{
  if (!identifier) {
    return nil;
  }
  if (![identifier isEqualToString:_activeSession.identifier]) {
    return nil;
  }
  return _activeSession;
}

+ (instancetype)sessionWithApplication:(FBApplication *)application
{
  FBSession *session = [FBSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.testedApplication = application;
  session.elementCache = [FBElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

- (void)kill
{
  [self.testedApplication terminate];
  _activeSession = nil;
}

- (FBApplication *)application
{
  FBApplication *application = self.testedApplication;
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"processIdentifier != %d", self.testedApplication.processID];
  XCAccessibilityElement *anotherActiveApplication = [[[[XCAXClient_iOS sharedClient] activeApplications] filteredArrayUsingPredicate:predicate] firstObject];
  if (anotherActiveApplication) {
    // If different active app is detected, using it instead of tested one
    application = [FBApplication appWithPID:anotherActiveApplication.processIdentifier];
  }
  else if (!application.running) {
    [[NSException exceptionWithName:FBApplicationCrashedException reason:@"Application is not running, possibly crashed" userInfo:nil] raise];
  }
  [application query];
  [application resolve];
  return application;
}

@end
