/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBConfiguration.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#include "TargetConditionals.h"
#import "XCTestPrivateSymbols.h"

BOOL _AXSAutomationSetFauxCollectionViewCellsEnabled(BOOL);

static NSUInteger const DefaultStartingPort = 8100;
static NSUInteger const DefaultPortRange = 100;

NSString *const FBUnknownSettingNameException = @"FBUnknownSettingNameException";

@implementation FBConfiguration

#pragma mark Public

+ (instancetype)sharedInstance
{
  static FBConfiguration *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)init
{
  if ((self = [super init])) {
    [self resetSettings];
  }
  return self;
}

- (void)resetSettings
{
  self.useAlternativeVisibilityDetection = NO;
  self.showVisibilityAttributeForXML = NO;
}

- (void)changeSettings:(NSDictionary<NSString *, id> *)newValues
{
  for (NSString *key in newValues) {
    if (![self.class.availableSettings containsObject:key]) {
      NSString *description = [NSString stringWithFormat:@"Setting '%@' is unknown. Valid setting names are: %@", key, [self.class.availableSettings sortedArrayUsingSelector:@selector(compare:)]];
      @throw [NSException exceptionWithName:FBUnknownSettingNameException reason:description userInfo:@{}];
    }
    [self setValue:[newValues objectForKey:key] forKey:key];
  }
}

- (NSDictionary<NSString *, id> *)currentSettings
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  for (NSString *settingName in self.class.availableSettings) {
    NSString *settingValue = [self valueForKey:settingName];
    if (nil == settingValue) {
      continue;
    }
    [result setObject:settingValue forKey:settingName];
  }
  return result.copy;
}

+ (void)shouldShowFakeCollectionViewCells:(BOOL)showFakeCells
{
  _AXSAutomationSetFauxCollectionViewCellsEnabled(showFakeCells);
}

+ (NSRange)bindingPortRange
{
  // 'WebDriverAgent --port 8080' can be passed via the arguments to the process
  if (self.bindingPortRangeFromArguments.location != NSNotFound) {
    return self.bindingPortRangeFromArguments;
  }

  // Existence of USE_PORT in the environment implies the port range is managed by the launching process.
  if (NSProcessInfo.processInfo.environment[@"USE_PORT"]) {
    return NSMakeRange([NSProcessInfo.processInfo.environment[@"USE_PORT"] integerValue] , 1);
  }

  return NSMakeRange(DefaultStartingPort, DefaultPortRange);
}

+ (BOOL)shouldListenOnUSB
{
#if TARGET_OS_SIMULATOR
  return NO;
#else
  return YES;
#endif
}

+ (BOOL)verboseLoggingEnabled
{
  return [NSProcessInfo.processInfo.environment[@"VERBOSE_LOGGING"] boolValue];
}

#pragma mark Private

+ (NSRange)bindingPortRangeFromArguments
{
  NSArray *arguments = NSProcessInfo.processInfo.arguments;
  NSUInteger index = [arguments indexOfObject:@"--port"];
  if (index == NSNotFound || index == arguments.count - 1) {
    return NSMakeRange(NSNotFound, 0);
  }
  NSString *portNumberString = arguments[index + 1];
  NSUInteger port = (NSUInteger)[portNumberString integerValue];
  if (port == 0) {
    return NSMakeRange(NSNotFound, 0);
  }
  return NSMakeRange(port, 1);
}

+ (NSArray<NSString *> *)availableSettings
{
  static NSArray<NSString *> *result;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    unsigned int propsCount = 0;
    NSMutableArray *propertyNames = [NSMutableArray array];
    objc_property_t *properties = class_copyPropertyList(self.class, &propsCount);
    for (unsigned int i = 0; i < propsCount; ++i) {
      objc_property_t property = properties[i];
      const char *name = property_getName(property);
      NSString *nsName = [NSString stringWithUTF8String:name];
      if (nil == nsName) {
        continue;
      }
      [propertyNames addObject:nsName];
    }
    free(properties);
    result = propertyNames.copy;
  });
  return result;
}

@end
