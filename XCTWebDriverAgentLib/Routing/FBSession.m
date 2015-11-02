/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSession.h"

#import "FBElementCache.h"
#import "XCUIApplication.h"
#import "XCUIElement.h"

@interface FBSession ()
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) XCUIApplication *application;
@property (nonatomic, strong, readwrite) FBElementCache *elementCache;
@end

@implementation FBSession

+ (NSArray *)activeSessions
{
  return [[self currentSessions] allValues];
}

+ (instancetype)sessionWithXCUIApplication:(XCUIApplication *)application
{
  FBSession *session = [FBSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.application = application;
  session.elementCache = [FBElementCache new];
  [self.class currentSessions][session.identifier] = session;
  return session;
}

+ (instancetype)sessionWithIdentifier:(NSString *)identifier
{
  if (!identifier) {
    return nil;
  }
  return [[[self.class currentSessions] allValues] lastObject];
  return [self.class currentSessions][identifier];
}

- (void)kill
{
  [[self.class currentSessions] removeObjectForKey:self.identifier];
}

+ (NSMutableDictionary *)currentSessions
{
  static NSMutableDictionary *_sessions;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sessions = [NSMutableDictionary dictionary];
  });
  return _sessions;
}

- (XCUIApplication *)application
{
  [_application resolve];
  return _application;
}
- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ -> %@", self.identifier, [self.application description]];
}

- (NSString *)debugDescription
{
  return [NSString stringWithFormat:@"<%p> %@", self, self.description];
}

@end
