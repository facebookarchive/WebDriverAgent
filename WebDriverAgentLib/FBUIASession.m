//
//  FBUIASession.m
//  WebDriverAgent
//
//  Created by Marek Cirkos on 09/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

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
