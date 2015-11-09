//
//  FBUIASession.h
//  WebDriverAgent
//
//  Created by Marek Cirkos on 09/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBSession.h"

@interface FBUIASession : FBSession

/**
 Creates new session with identifier
 
 @param identifier Identifer for new session
 @return session.
 */
+ (instancetype)newSessionWithIdentifier:(NSString *)identifier;

@end
