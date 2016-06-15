/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIApplication+FBHelpers.h"

#import "FBSpringboardApplication.h"
#import "XCElementSnapshot.h"
#import "FBElementTypeTransformer.h"
#import "FBMacros.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+WebDriverAttributes.h"
#import "XCElementSnapshot+Helpers.h"

@implementation XCUIApplication (FBHelpers)

- (BOOL)fb_deactivateWithDuration:(NSTimeInterval)duration error:(NSError **)error
{
  NSString *applicationIdentifier = self.label;
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];
  if (![[FBSpringboardApplication fb_springboard] fb_tapApplicationWithIdentifier:applicationIdentifier error:error]) {
    return NO;
  }
  return YES;
}

- (NSDictionary *)fb_tree
{
  return [self.class dictionaryForElement:self.lastSnapshot];
}

- (NSDictionary *)fb_accessibilityTree
{
  // We ignore all elements except for the main window for accessibility tree
  XCElementSnapshot *mainWindowSnapshot = [self.lastSnapshot fb_mainWindow];
  return [self.class accessibilityInfoForElement:mainWindowSnapshot];
}

+ (NSDictionary *)dictionaryForElement:(XCElementSnapshot *)snapshot
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
  info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
  info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
  info[@"name"] = FBValueOrNull(snapshot.wdName);
  info[@"value"] = FBValueOrNull(snapshot.wdValue);
  info[@"label"] = FBValueOrNull(snapshot.wdLabel);
  info[@"rect"] = snapshot.wdRect;
  info[@"frame"] = NSStringFromCGRect(snapshot.wdFrame);
  info[@"isEnabled"] = [@([snapshot isWDEnabled]) stringValue];
  info[@"isVisible"] = [@([snapshot isWDVisible]) stringValue];

  NSArray *childElements = snapshot.children;
  if ([childElements count]) {
    info[@"children"] = [[NSMutableArray alloc] init];
    for (XCElementSnapshot *childSnapshot in childElements) {
      [info[@"children"] addObject:[self dictionaryForElement:childSnapshot]];
    }
  }
  return info;
}

+ (NSDictionary *)accessibilityInfoForElement:(XCElementSnapshot *)snapshot
{
  BOOL isAccessible = [snapshot isWDAccessible];
  BOOL isVisible = [snapshot isWDVisible];
  if (!isVisible) {
    return nil;
  }

  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

  if (isAccessible) {
    info[@"value"] = FBValueOrNull(snapshot.wdValue);
    info[@"label"] = FBValueOrNull(snapshot.wdLabel);
  } else {
    NSArray *childElements = snapshot.children;
    if ([childElements count]) {
      info[@"children"] = [[NSMutableArray alloc] init];
      for (XCElementSnapshot *childSnapshot in childElements) {
        NSDictionary *childInfo = [self accessibilityInfoForElement:childSnapshot];
        if ([childInfo count]) {
          [info[@"children"] addObject: childInfo];
        }
      }
    }
  }
  if ([info count]) {
    info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
    info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
    info[@"name"] = FBValueOrNull(snapshot.wdName);
  }
  return info;
}

@end
