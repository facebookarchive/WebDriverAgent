//
//  XCUIApplication+FBFocused.m
//  WebDriverAgentLib_tvOS
//
//  Created by Pavel Serdiukov on 8/6/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "XCUIApplication+FBFocused.h"

@implementation XCUIApplication (FBFocused)

- (XCUIElement*) fb_focusedElement {
  XCUIElementQuery *query = [self descendantsMatchingType:XCUIElementTypeAny];
  return [query elementMatchingPredicate: [NSPredicate predicateWithFormat:@"hasFocus == true"]];
}

@end
