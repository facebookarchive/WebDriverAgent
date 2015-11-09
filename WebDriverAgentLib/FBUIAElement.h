//
//  FBUIAElement.h
//  WebDriverAgent
//
//  Created by Marek Cirkos on 06/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebDriverAgentLib/FBElement.h>

@class UIAElement;

@interface FBUIAElement : NSObject <FBElement>
@property (nonatomic, strong, readonly) UIAElement *uiaElement;

+ (instancetype)targetElement;
+ (instancetype)applicationElement;
+ (instancetype)elementWithUIAElement:(UIAElement *)uiaElement;

@end
