//
//  XCUIElement+FBFocuse.m
//  WebDriverAgentLib_tvOS
//
//  Created by Pavel Serdiukov on 9/13/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "XCUIElement+FBFocuse.h"

#import "XCUIApplication+FBFocused.h"
#import "FBApplication.h"
#import "FBErrorBuilder.h"

@implementation XCUIElement (FBFocuse)

-(BOOL) fb_focuseInRowWithError:(NSError**) error {
  
  BOOL isEndReached = NO;
  FBApplication *app = [FBApplication fb_activeApplication];
  while (!self.exists || !self.hasFocus) {
    NSString *previous = [[app fb_focusedElement] description];
    [[XCUIRemote sharedRemote] pressButton: isEndReached ? XCUIRemoteButtonUp: XCUIRemoteButtonDown];
    NSString *current = [[app fb_focusedElement] description];
    if (previous == current) {
      if (isEndReached) {
        [[[FBErrorBuilder builder] withDescription:@"Element was not found in column or could not be focused."]
         buildError:error];
        return NO;
        isEndReached = YES;
      }
    }
  }
  return YES;
}

@end
