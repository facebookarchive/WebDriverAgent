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
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIDevice+FBHelpers.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

const static NSTimeInterval FBMinimumAppSwitchWait = 3.0;

@implementation XCUIApplication (FBHelpers)

- (BOOL)fb_deactivateWithDuration:(NSTimeInterval)duration error:(NSError **)error
{
  NSString *applicationIdentifier = self.label;
  XCUIApplication *previousApplication = self;
  if(![[XCUIDevice sharedDevice] fb_goToHomescreenWithError:error]) {
    return NO;
  }
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:MAX(duration, FBMinimumAppSwitchWait)]];
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
    [previousApplication activate];
    return YES;
  }
  if (![[FBSpringboardApplication fb_springboard] fb_tapApplicationWithIdentifier:applicationIdentifier error:error]) {
    return NO;
  }
  return YES;
}

- (NSDictionary *)fb_tree
{
  [self fb_waitUntilSnapshotIsStable];
  return [self.class dictionaryForElement:self.fb_lastSnapshot];
}

- (NSDictionary *)fb_accessibilityTree
{
  [self fb_waitUntilSnapshotIsStable];
  // We ignore all elements except for the main window for accessibility tree
  return [self.class accessibilityInfoForElement:self.fb_lastSnapshot];
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

  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

  if (isAccessible) {
    if (isVisible) {
      info[@"value"] = FBValueOrNull(snapshot.wdValue);
      info[@"label"] = FBValueOrNull(snapshot.wdLabel);
    }
  } else {
    NSMutableArray *children = [[NSMutableArray alloc] init];
    for (XCElementSnapshot *childSnapshot in snapshot.children) {
      NSDictionary *childInfo = [self accessibilityInfoForElement:childSnapshot];
      if ([childInfo count]) {
        [children addObject: childInfo];
      }
    }
    if ([children count]) {
      info[@"children"] = [children copy];
    }
  }
  if ([info count]) {
    info[@"type"] = [FBElementTypeTransformer shortStringWithElementType:snapshot.elementType];
    info[@"rawIdentifier"] = FBValueOrNull([snapshot.identifier isEqual:@""] ? nil : snapshot.identifier);
    info[@"name"] = FBValueOrNull(snapshot.wdName);
  } else {
    return nil;
  }
  return info;
}

@end
