//
//  FBSession.m
//  WebDriverAgent
//
//  Created by Marek Cirkos on 09/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "FBSession.h"
#import "FBSession-Private.h"

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

- (void)kill
{
  _activeSession = nil;
}

@end
