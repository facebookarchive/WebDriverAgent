/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import <WebDriverAgentLib/XCElementSnapshot.h>
#import <WebDriverAgentLib/FBElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBUtilities)

/**
 Waits for receiver's frame to become stable with timeout
 */
- (BOOL)fb_waitUntilFrameIsStable;

/**
 Checks if receiver is obstructed by alert
 */
- (BOOL)fb_isObstructedByAlert;

/**
 Checks if receiver obstructs given element

 @param element tested element
 @return YES if receiver obstructs 'element', otherwise NO
 */
- (BOOL)fb_obstructsElement:(XCUIElement *)element;

/**
 Gets the most recent snapshot of the current element. The element will be
 automatically resolved if the snapshot is not available yet

 @return The recent snapshot of the element
 */
- (XCElementSnapshot *)fb_lastSnapshot;

/**
 Gets the most recent snapshot of the current element from the query snapshot that found the element.
 fb_lastSnapshot actually resolves the query for that element, which then creates a new complete
 snapshot from the device, and filters it down to the element. This is slow. This method on the other
 hand finds the root query, obtains the rootSnapshot tree from that query, then applies the element's
 query to each snapshot object to find it's corresponding snapshot.
 
 @return The recent snapshot of the element
 */
- (XCElementSnapshot *)fb_lastSnapshotFromQuery;

/**
 Filters elements by matching them to snapshots from the corresponding array

 @param snapshots Array of snapshots to be matched with

 @return Array of filtered elements, which have matches in snapshots array
 */
- (NSArray<XCUIElement *> *)fb_filterDescendantsWithSnapshots:(NSArray<XCElementSnapshot *> *)snapshots;

/**
 Waits until element snapshot is stable to avoid "Error copying attributes -25202 error".
 This error usually happens for testmanagerd if there is an active UI animation in progress and
 causes 15-seconds delay while getting hitpoint value of element's snapshot.

 @return YES if wait succeeded ortherwise NO if there is still some active animation in progress
*/
- (BOOL)fb_waitUntilSnapshotIsStable;

/**
 Returns screenshot of the particular element
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return Element screenshot as PNG-encoded data or nil in case of failure
 */
- (nullable NSData *)fb_screenshotWithError:(NSError*__autoreleasing*)error;

@end

NS_ASSUME_NONNULL_END
