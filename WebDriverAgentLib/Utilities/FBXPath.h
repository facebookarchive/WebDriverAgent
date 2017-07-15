/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCUIElementTypes.h>
#import <WebDriverAgentLib/FBElement.h>
#import <WebDriverAgentLib/XCElementSnapshot.h>

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#endif

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>

#ifdef __clang__
#pragma clang diagnostic pop
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 The exception happends if the provided XPath expession cannot be compiled because of a syntax error
 */
extern NSString *const XCElementSnapshotInvalidXPathException;
/**
 The exception happends if any internal error is triggered during XPath matching procedure
 */
extern NSString *const XCElementSnapshotXPathQueryEvaluationException;

@interface FBXPath : NSObject

/**
 Returns an array of descendants matching given xpath query
 
 @param root the root element to execute XPath query for. Can be an instance of XCUIElement or XCElementSnapshot (faster, but does not work under iOS 11+) interfaces
 @param xpathQuery requested xpath query
 @return an array of descendants matching given xpath query. The actual type of returned descendants relies on the type of the root argument. If the root argument is an instance of XCUIElement then array of matching XCUIElement instances is going to be returned otherwise the array of XCElementSnapshot instances is returned. The lookup performance in case the root element is set to XCUIElement instance is lower, but this is the only available option under iOS 11+, where snapshotting feature has been slightly limited
 */
+ (nullable NSArray<id<FBElement>> *)findMatchesIn:(id<FBElement>)root xpathQuery:(NSString *)xpathQuery;

/**
 Gets XML representation of XCElementSnapshot with all its descendants. This method generates the same
 representation, which is used for XPath search
 
 @param root the root element. Can be an instance of XCUIElement or XCElementSnapshot (faster, but does not work under iOS 11+) interfaces
 @return valid XML document as string or nil in case of failure
 */
+ (nullable NSString *)xmlStringWithElement:(id<FBElement>)root;

@end

NS_ASSUME_NONNULL_END
