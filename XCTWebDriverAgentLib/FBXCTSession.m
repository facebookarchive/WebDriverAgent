/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "FBXCTSession.h"

#import "FBElementCache.h"
#import "FBSession-Private.h"

#import "XCUIApplication.h"
#import "XCUIElement.h"

#import "FBXCTElementCache.h"

NSString *const FBApplicationCrashedException = @"FBApplicationCrashedException";

@interface FBXCTSession ()
@property (nonatomic, strong, readwrite) XCUIApplication *application;
@end

@implementation FBXCTSession

+ (instancetype)sessionWithXCUIApplication:(XCUIApplication *)application
{
  FBXCTSession *session = [FBXCTSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.application = application;
  session.elementCache = [FBXCTElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

- (XCUIApplication *)application
{
  if (!_application.running) {
    [[NSException exceptionWithName:FBApplicationCrashedException reason:@"Application is not running, possibly crashed" userInfo:nil] raise];
  }
  [_application resolve];
  return _application;
}

- (void)kill
{
  [self.application terminate];
  [super kill];
}

@end
