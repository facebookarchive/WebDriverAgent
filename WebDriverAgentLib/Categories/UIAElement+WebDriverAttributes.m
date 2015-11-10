/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIAElement+WebDriverAttributes.h"

#import <UIKit/UIKit.h>

#import "FBWDAMacros.h"

@implementation UIAElement (WebDriverAttributes)

- (CGRect)wdFrame
{
  return [self.rect CGRectValue];
}

- (NSDictionary *)wdRect
{
  CGRect rect = self.wdFrame;
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

- (NSString *)wdName
{
  return self.name;
}

- (NSString *)wdLabel
{
  return self.label;
}

- (NSString *)wdType
{
  return NSStringFromClass(self.class);
}

- (id)wdValue
{
  return self.value;
}

- (BOOL)isWDEnabled
{
  return self.isEnabled.boolValue;
}

- (BOOL)isWDVisible
{
  return self.isVisible.boolValue;
  
}

- (id)valueForWDAttributeName:(NSString *)name
{
  FBWDAAssertMainThread();
  [UIAElement pushPatience:0];
  id value = [self valueForKey:wdAttributeNameForAttributeName(name)];
  [UIAElement popPatience];
  return value;
}

@end
