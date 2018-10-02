//
//  XCUIElement+FBFocuse.h
//  WebDriverAgentLib_tvOS
//
//  Created by Pavel Serdiukov on 9/13/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBTVInteract)

-(BOOL) fb_focuseInRowWithError:(NSError**) error;

@end

NS_ASSUME_NONNULL_END
