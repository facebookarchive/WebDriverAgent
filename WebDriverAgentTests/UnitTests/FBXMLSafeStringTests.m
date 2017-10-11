/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import "NSString+FBXMLSafeString.h"

@interface FBXMLSafeStringTests : XCTestCase
@end

@implementation FBXMLSafeStringTests

- (void)testSafeXmlStringTransformationWithEmptyReplacement {
  NSString *withInvalidChar = [NSString stringWithFormat:@"bla%@", @"\uFFFF"];
  NSString *withoutInvalidChar = @"bla";
  XCTAssertNotEqualObjects(withInvalidChar, withoutInvalidChar);
  XCTAssertEqualObjects([withInvalidChar fb_xmlSafeStringWithReplacement:@""], withoutInvalidChar);
}

- (void)testSafeXmlStringTransformationWithNonEmptyReplacement {
  NSString *withInvalidChar = [NSString stringWithFormat:@"bla%@", @"\uFFFF"];
  XCTAssertEqualObjects([withInvalidChar fb_xmlSafeStringWithReplacement:@"1"], @"bla1");
}

- (void)testSafeXmlStringTransformationWithSmileys {
  NSString *validString = @"Yo👿";
  XCTAssertEqualObjects([validString fb_xmlSafeStringWithReplacement:@""], validString);
}

@end
