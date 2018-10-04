//
//  XCUIElement+FBTVInteract.m
//  WebDriverAgentLib_tvOS
//
//  Created by Pavel Serdiukov on 9/13/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "XCUIElement+FBTVInteract.h"

#import "XCUIApplication+FBFocused.h"
#import "FBApplication.h"
#import "FBErrorBuilder.h"
#import <XCTest/XCUIRemote.h>
#import "XCUIElement+FBWebDriverAttributes.h"


@implementation XCUIElement (FBTVInteract)

-(BOOL) fb_focuseInRowWithError:(NSError**) error
{
  BOOL isEndReached = NO;
  FBApplication *app = [FBApplication fb_activeApplication];
  while (!self.exists || !self.hasFocus) {
    NSUInteger previous = [app fb_focusedElement].wdUID;
    [[XCUIRemote sharedRemote] pressButton: isEndReached ? XCUIRemoteButtonUp: XCUIRemoteButtonDown];
    NSUInteger current = [app fb_focusedElement].wdUID;
    if (previous == current) {
      if (isEndReached) {
        [[[FBErrorBuilder builder] withDescription:@"Element was not found in column or could not be focused."]
         buildError:error];
        return NO;
      }
      isEndReached = YES;
    }
  }
  return YES;
}

-(BOOL) fb_selectInRowWithError:(NSError**) error
{
  BOOL result = [self fb_focuseInRowWithError: error];
  if (result) {
    [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonSelect];
  }
  return result;
}
@end
