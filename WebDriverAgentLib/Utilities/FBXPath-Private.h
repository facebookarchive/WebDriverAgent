/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/FBXPath.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBXPath ()

/**
 Gets xmllib2-compatible XML representation of n XCElementSnapshot instance
 
 @param root the root element to execute XPath query for
 @param writer the correspondig libxml2 writer object
 @param elementStore an empty dictionary to store indexes mapping or nil if no mappings should be stored
 @return zero if the method has completed successfully
 */
+ (int)getSnapshotAsXML:(XCElementSnapshot *)root writer:(xmlTextWriterPtr)writer elementStore:(nullable NSMutableDictionary *)elementStore;

/**
 Gets the list of matched snapshots from xmllib2-compatible xmlNodeSetPtr structure
 
 @param nodeSet set of nodes returned after successful XPath evaluation
 @param elementStore dictionary containing index->snapshot mapping
 @return array of filtered elements or nil in case of failure. Can be empty array as well
 */
+ (NSArray *)collectMatchingSnapshots:(xmlNodeSetPtr)nodeSet elementStore:(NSMutableDictionary *)elementStore;

/**
 Gets the list of matched XPath nodes from xmllib2-compatible XML document
 
 @param xpathQuery actual query. Should be valid XPath 1.0-compatible expression
 @param document libxml2-compatible document pointer
 @return pointer to a libxml2-compatible structure with set of matched nodes or NULL in case of failure
 */
+ (xmlXPathObjectPtr)evaluate:(NSString *)xpathQuery document:(xmlDocPtr)doc;

@end

NS_ASSUME_NONNULL_END
