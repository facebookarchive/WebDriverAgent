/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRuntimeUtils.h"

#import "FBMacros.h"
#import "XCUIDevice.h"

#include <dlfcn.h>
#import <objc/runtime.h>

NSArray<Class> *FBClassesThatConformsToProtocol(Protocol *protocol)
{
  Class *classes = NULL;
  NSMutableArray *collection = [NSMutableArray array];
  int numClasses = objc_getClassList(NULL, 0);
  if (numClasses == 0 ) {
    return @[];
  }

  classes = (__unsafe_unretained Class*)malloc(sizeof(Class) * numClasses);
  numClasses = objc_getClassList(classes, numClasses);
  for (int index = 0; index < numClasses; index++) {
    Class aClass = classes[index];
    if (class_conformsToProtocol(aClass, protocol)) {
      [collection addObject:aClass];
    }
  }
  free(classes);
  return collection.copy;
}

void *FBRetrieveSymbolFromBinary(const char *binary, const char *name)
{
  void *handle = dlopen(binary, RTLD_LAZY);
  NSCAssert(handle, @"%s could not be opened", binary);
  void *pointer = dlsym(handle, name);
  NSCAssert(pointer, @"%s could not be located", name);
  return pointer;
}

static NSString *sdkVersion = nil;
static dispatch_once_t onceSdkVersionToken;
NSString * _Nullable FBSDKVersion()
{
  dispatch_once(&onceSdkVersionToken, ^{
    NSString *sdkName = [[NSBundle mainBundle] infoDictionary][@"DTSDKName"];
    if (sdkName) {
      // the value of DTSDKName looks like 'iphoneos9.2'
      NSRange versionRange = [sdkName rangeOfString:@"\\d+\\.\\d+" options:NSRegularExpressionSearch];
      if (versionRange.location != NSNotFound) {
        sdkVersion = [sdkName substringWithRange:versionRange];
      }
    }
  });
  return sdkVersion;
}

BOOL isSDKVersionLessThan(NSString *expected)
{
  NSString *version = FBSDKVersion();
  if (nil == version) {
    return SYSTEM_VERSION_LESS_THAN(expected);
  }
  NSComparisonResult result = [version compare:expected options:NSNumericSearch];
  return result == NSOrderedAscending;
}

BOOL isSDKVersionLessThanOrEqualTo(NSString *expected)
{
  NSString *version = FBSDKVersion();
  if (nil == version) {
    return SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(expected);
  }
  NSComparisonResult result = [version compare:expected options:NSNumericSearch];
  return result == NSOrderedAscending || result == NSOrderedSame;
}

BOOL isSDKVersionEqualTo(NSString *expected)
{
  NSString *version = FBSDKVersion();
  if (nil == version) {
    return SYSTEM_VERSION_EQUAL_TO(expected);
  }
  NSComparisonResult result = [version compare:expected options:NSNumericSearch];
  return result == NSOrderedSame;
}

BOOL isSDKVersionGreaterThanOrEqualTo(NSString *expected)
{
  NSString *version = FBSDKVersion();
  if (nil == version) {
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(expected);
  }
  NSComparisonResult result = [version compare:expected options:NSNumericSearch];
  return result == NSOrderedDescending || result == NSOrderedSame;
}

BOOL isSDKVersionGreaterThan(NSString *expected)
{
  NSString *version = FBSDKVersion();
  if (nil == version) {
    return SYSTEM_VERSION_GREATER_THAN(expected);
  }
  NSComparisonResult result = [version compare:expected options:NSNumericSearch];
  return result == NSOrderedDescending;
}
