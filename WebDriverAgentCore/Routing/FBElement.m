/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElement.h"

#import "FBCoreExceptionHandler.h"

NSString *wdAttributeNameForAttributeName(NSString *name)
{
  static dispatch_once_t onceToken;
  static NSSet *allowedAttributes;
  dispatch_once(&onceToken, ^{
    allowedAttributes = [NSSet setWithArray:@[@"name", @"type", @"value", @"label", @"frame", @"rect", @"size", @"location"]];
  });
  if (![allowedAttributes containsObject:name.lowercaseString]) {
    [[NSException exceptionWithName:FBElementAttributeUnknownException reason:[NSString stringWithFormat:@"Invalid locator requested: %@", name] userInfo:nil] raise];
  }
  return [NSString stringWithFormat:@"wd%@", name.capitalizedString];
}
