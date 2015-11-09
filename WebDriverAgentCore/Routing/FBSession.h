//
//  FBSession.h
//  WebDriverAgent
//
//  Created by Marek Cirkos on 09/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FBElementCache;

@interface FBSession : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) id <FBElementCache> elementCache;

+ (instancetype)activeSession;

/**
 Fetches session for given identifier.
 If identifier doesn't match activeSession identifier, will return nil.
 
 @param identifier Identifer for searched session
 @return session. Can return nil if session does not exists
 */
+ (instancetype)sessionWithIdentifier:(NSString *)identifier;

/**
 Kills application associated with that session and removes session
 */
- (void)kill;

@end
