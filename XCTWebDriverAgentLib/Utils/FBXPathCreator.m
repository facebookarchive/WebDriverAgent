/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBXPathCreator.h"

#import "FBElementTypeTransformer.h"

@implementation FBXPathCreator

+ (NSString *)xpathWithSubelementsOfType:(XCUIElementType)elementType
{
  return [NSString stringWithFormat:@"//%@", [FBElementTypeTransformer stringWithElementType:elementType]];
}

@end
