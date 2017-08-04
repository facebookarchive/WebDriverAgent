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
#import "FBMacros.h"
#import "FBSpringboardApplication.h"
#import "XCAccessibilityElement.h"
#import "XCAXClient_iOS.h"
#import "XCUIElement.h"

NSString *const FBApplicationCrashedException = @"FBApplicationCrashedException";

@interface FBSession ()
@property (class, nonatomic, strong, readonly) NSMutableSet<FBSession *> *sessions;
@property (nonatomic, strong, readwrite) FBApplication *testedApplication;
@end

@implementation FBSession

static FBSession *_activeSession;
+ (instancetype)activeSession
{
  return _activeSession ?: [FBSession sessionWithApplication:nil];
}

+ (void)killAll
{
  while (self.sessions.count > 0) {
    FBSession *session = [self.sessions anyObject];
    [session kill];
  }
}

+ (void)markSessionActive:(FBSession *)session
{
  _activeSession = session;
}

+ (NSMutableSet<FBSession *> *)sessions
{
  static NSMutableSet<FBSession *> *_sessions;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sessions = [[NSMutableSet<FBSession *> alloc] init];
  });

  return _sessions;
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
  [FBSession.sessions addObject:session];
  [FBSession markSessionActive:session];
  return session;
}

- (void)kill
{
  [self.testedApplication terminate];
  [FBSession.sessions removeObject:self];

  if ([self isEqual:_activeSession]) {
    _activeSession = nil;
  }
}

- (FBApplication *)application
{
  FBApplication *application = [FBApplication fb_activeApplication];
  const BOOL testedApplicationIsActiveAndNotRunning = (application.processID == self.testedApplication.processID && !application.running);
  if (testedApplicationIsActiveAndNotRunning) {
    [[NSException exceptionWithName:FBApplicationCrashedException reason:@"Application is not running, possibly crashed" userInfo:nil] raise];
  }
  [application query];
  [application resolve];
  return application;
}

@end
