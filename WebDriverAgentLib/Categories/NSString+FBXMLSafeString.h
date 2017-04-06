/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (FBXMLSafeString)

/**
 Method used to normalize a string before passing it to XML document
 
 @param replacement The string to be used as a replacement for invalid XML characters
 @return The string where all characters, which are not members of
         XML Character Range definition (http://www.w3.org/TR/2008/REC-xml-20081126/#charsets),
         are replaced
 */
- (NSString *)fb_xmlSafeStringWithReplacement:(NSString *)replacement;

@end

NS_ASSUME_NONNULL_END
