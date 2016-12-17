/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "FBApplicationDouble.h"
#import "FBSession.h"

@interface FBSessionTests : XCTestCase
@property (nonatomic, strong) FBSession *session;
@property (nonatomic, strong) FBApplication *testedApplication;
@end

@implementation FBSessionTests

- (void)setUp
{
  [super setUp];
  self.testedApplication = (id)FBApplicationDouble.new;
  self.session = [FBSession sessionWithApplication:self.testedApplication];
}

- (void)testSessionFetching
{
  FBSession *fetchedSession = [FBSession sessionWithIdentifier:self.session.identifier];
  XCTAssertEqual(self.session, fetchedSession);
}

- (void)testSessionFetchingBadIdentifier
{
  XCTAssertNil([FBSession sessionWithIdentifier:@"FAKE_IDENTIFIER"]);
}

- (void)testSessionCreation
{
  XCTAssertNotNil(self.session.identifier);
  XCTAssertNotNil(self.session.elementCache);
}

- (void)testActiveSession
{
  XCTAssertEqual(self.session, [FBSession activeSession]);
}

- (void)testAfterKillingSessionShouldCreateNewOne
{
  NSString *sessionIdentifier = self.session.identifier;
  [self.session kill];
  XCTAssertTrue(((FBApplicationDouble *)self.testedApplication).didTerminate);
  XCTAssertNotNil([FBSession activeSession]);
  XCTAssertNotEqual([FBSession activeSession].identifier, sessionIdentifier);
}

@end
