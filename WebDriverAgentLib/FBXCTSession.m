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
#import "FBXCTElementCache.h"
#import "XCAXClient_iOS.h"
#import "XCAccessibilityElement.h"
#import "XCUIApplication.h"
#import "XCUIElement.h"

NSString *const FBApplicationCrashedException = @"FBApplicationCrashedException";

@interface FBXCTSession ()
@property (nonatomic, strong, readwrite) XCUIApplication *testedApplication;
@end

@implementation FBXCTSession

+ (instancetype)sessionWithXCUIApplication:(XCUIApplication *)application
{
  FBXCTSession *session = [FBXCTSession new];
  session.identifier = [[NSUUID UUID] UUIDString];
  session.testedApplication = application;
  session.elementCache = [FBXCTElementCache new];
  [FBSession markSessionActive:session];
  return session;
}

- (XCUIApplication *)application
{
  XCUIApplication *application = self.testedApplication;
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"processIdentifier != %d", self.testedApplication.processID];
  XCAccessibilityElement *anotherActiveApplication = [[[[XCAXClient_iOS sharedClient] activeApplications] filteredArrayUsingPredicate:predicate] firstObject];
  if (anotherActiveApplication) {
    // If different active app is detected, using it instead of tested one
    application = [XCUIApplication appWithPID:anotherActiveApplication.processIdentifier];
  }
  else if (!application.running) {
    [[NSException exceptionWithName:FBApplicationCrashedException reason:@"Application is not running, possibly crashed" userInfo:nil] raise];
  }
  [application query];
  [application resolve];
  return application;
}

- (void)kill
{
  [self.testedApplication terminate];
  [super kill];
}

@end
