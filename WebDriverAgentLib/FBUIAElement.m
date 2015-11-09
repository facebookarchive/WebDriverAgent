//
//  FBUIAElement.m
//  WebDriverAgent
//
//  Created by Marek Cirkos on 06/11/2015.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "FBUIAElement.h"
#import "FBWDAMacros.h"

#import "UIAApplication.h"
#import "UIAElement.h"
#import "UIATarget.h"

@interface FBUIAElement ()
@property (nonatomic, strong, readwrite) UIAElement *uiaElement;
@end

@implementation FBUIAElement

+ (instancetype)targetElement
{
  return [self elementWithUIAElement:[UIATarget localTarget]];
}

+ (instancetype)applicationElement
{
  return [self elementWithUIAElement:[UIATarget localTarget].frontMostApp];
}

+ (instancetype)elementWithUIAElement:(UIAElement *)uiaElement;
{
  FBUIAElement *element = [FBUIAElement new];
  element.uiaElement = uiaElement;
  return element;
}

- (CGRect)frame
{
  return [self.uiaElement.rect CGRectValue];
}

- (NSDictionary *)rect
{
  CGRect rect = self.frame;
  return
  @{
    @"origin": @{
        @"x": @(rect.origin.x),
        @"y": @(rect.origin.y),
        },
    @"size": @{
        @"width": @(rect.size.width),
        @"height": @(rect.size.height),
        },
    };
}

- (BOOL)isVisible
{
  return self.uiaElement.isVisible.boolValue;
}

- (BOOL)isEnabled
{
  return self.uiaElement.isEnabled.boolValue;
}

- (NSString *)type
{
  return [self.uiaElement className];
}

- (NSString *)name
{
  return self.uiaElement.name;
}

- (NSString *)label
{
  return self.uiaElement.label;
}

- (id)value
{
  return self.uiaElement.value;
}

- (id)valueForKey:(NSString *)key
{
  FBWDAAssertMainThread();
  [UIAElement pushPatience:0];
  id value = [super valueForKey:key];
  [UIAElement popPatience];
  return value;
}

@end
