//
//  XCUIRemote+Tap.m
//  WebDriverAgent (tvOS)
//
//  Created by George Maisuradze on 12/06/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "XCUIRemote+FBTap.h"

@implementation XCUIRemote (FBTap)

- (void) fb_pressMenu {
  [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonMenu];
}

- (void) fb_pressSelect {
  [[XCUIRemote sharedRemote] pressButton:XCUIRemoteButtonSelect];
}

@end
