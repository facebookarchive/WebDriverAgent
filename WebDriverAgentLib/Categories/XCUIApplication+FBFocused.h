//
//  XCUIApplication+FBFocused.h
//  WebDriverAgentLib_tvOS
//
//  Created by Pavel Serdiukov on 8/6/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIApplication (FBFocused)

/**
 Return current focused element
  */
- (XCUIElement*) fb_focusedElement;

@end

NS_ASSUME_NONNULL_END
