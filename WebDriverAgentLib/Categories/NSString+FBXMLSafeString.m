/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "NSString+FBXMLSafeString.h"

@implementation NSString (FBXMLSafeString)

- (NSString *)fb_xmlSafeStringWithReplacement:(NSString *)replacement
{
  static NSMutableCharacterSet *invalidSet;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
    invalidSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(0x9, 1)];
    [invalidSet addCharactersInRange:NSMakeRange(0xA, 1)];
    [invalidSet addCharactersInRange:NSMakeRange(0xD, 1)];
    [invalidSet addCharactersInRange:NSMakeRange(0x20, 0xD7FF - 0x20 + 1)];
    [invalidSet addCharactersInRange:NSMakeRange(0xE000, 0xFFFD - 0xE000 + 1)];
    [invalidSet addCharactersInRange:NSMakeRange(0x10000, 0x10FFFF - 0x10000 + 1)];
    [invalidSet invert];
  });
  return [[self componentsSeparatedByCharactersInSet:invalidSet] componentsJoinedByString:replacement];
}

@end
