/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCElementSnapshot+Helpers.h"

#import "FBFindElementCommands.h"
#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBXPathCreator.h"
#import "XCAXClient_iOS.h"
#import "XCTestDriver.h"
#import "XCTestPrivateSymbols.h"

inline static BOOL valuesAreEqual(id value1, id value2);

@implementation XCElementSnapshot (Helpers)

- (NSArray<XCElementSnapshot *> *)fb_descendantsMatchingType:(XCUIElementType)type
{
  return [FBFindElementCommands descendantsOfElementSnapshot:self withXPathQuery:[FBXPathCreator xpathWithSubelementsOfType:type]];
}

- (XCElementSnapshot *)fb_parentMatchingType:(XCUIElementType)type
{
  XCElementSnapshot *snapshot = self.parent;
  while (snapshot && snapshot.elementType != type) {
    snapshot = snapshot.parent;
  }
  return snapshot;
}

- (id)fb_attributeValue:(NSNumber *)attribute
{
  NSDictionary *attributesResult = [[XCAXClient_iOS sharedClient] attributesForElementSnapshot:self attributeList:@[attribute]];
  return attributesResult[attribute];
}

- (BOOL)fb_framelessFuzzyMatchesElement:(XCElementSnapshot *)snapshot
{
  return self.elementType == snapshot.elementType &&
    valuesAreEqual(self.identifier, snapshot.identifier) &&
    valuesAreEqual(self.title, snapshot.title) &&
    valuesAreEqual(self.label, snapshot.label) &&
    valuesAreEqual(self.value, snapshot.value) &&
    valuesAreEqual(self.placeholderValue, snapshot.placeholderValue);
}

@end

inline static BOOL valuesAreEqual(id value1, id value2)
{
  return value1 == value2 || [value1 isEqual:value2];
}
