/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBUtilities.h"

#import <objc/runtime.h>

#import "FBAlert.h"
#import "FBLogger.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBPredicate.h"
#import "FBRunLoopSpinner.h"
#import "FBXCodeCompatibility.h"
#import "XCAXClient_iOS.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "XCUIElementQuery.h"
#import "XCUIScreen.h"

@implementation XCUIElement (FBUtilities)

static const NSTimeInterval FBANIMATION_TIMEOUT = 5.0;

- (BOOL)fb_waitUntilFrameIsStable
{
  __block CGRect frame;
  // Initial wait
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  return
  [[[FBRunLoopSpinner new]
     timeout:10.]
   spinUntilTrue:^BOOL{
     [self resolve];
     const BOOL isSameFrame = FBRectFuzzyEqualToRect(self.wdFrame, frame, FBDefaultFrameFuzzyThreshold);
     frame = self.wdFrame;
     return isSameFrame;
   }];
}

- (BOOL)fb_isObstructedByAlert
{
  return [[FBAlert alertWithApplication:self.application].alertElement fb_obstructsElement:self];
}

- (BOOL)fb_obstructsElement:(XCUIElement *)element
{
  if (!self.exists) {
    return NO;
  }
  XCElementSnapshot *snapshot = self.fb_lastSnapshot;
  XCElementSnapshot *elementSnapshot = element.fb_lastSnapshot;
  if ([snapshot _isAncestorOfElement:elementSnapshot]) {
    return NO;
  }
  if ([snapshot _matchesElement:elementSnapshot]) {
    return NO;
  }
  return YES;
}

- (XCElementSnapshot *)fb_lastSnapshot
{
  [self resolve];
  return [[self query] elementSnapshotForDebugDescription];
}

- (NSArray<XCUIElement *> *)fb_filterDescendantsWithSnapshots:(NSArray<XCElementSnapshot *> *)snapshots
{
  if (0 == snapshots.count) {
    return @[];
  }
  NSArray<NSNumber *> *matchedUids = [snapshots valueForKey:FBStringify(XCUIElement, wdUID)];
  NSMutableArray<XCUIElement *> *matchedElements = [NSMutableArray array];
  if ([matchedUids containsObject:@(self.wdUID)]) {
    if (1 == snapshots.count) {
      return @[self];
    }
    [matchedElements addObject:self];
  }
  XCUIElementType type = XCUIElementTypeAny;
  NSArray<NSNumber *> *uniqueTypes = [snapshots valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOfObjects.%@", FBStringify(XCUIElement, elementType)]];
  if (uniqueTypes && [uniqueTypes count] == 1) {
    type = [uniqueTypes.firstObject intValue];
  }
  XCUIElementQuery *query = [[self descendantsMatchingType:type] matchingPredicate:[FBPredicate predicateWithFormat:@"%K IN %@", FBStringify(XCUIElement, wdUID), matchedUids]];
  if (1 == snapshots.count) {
    XCUIElement *result = query.fb_firstMatch;
    return result ? @[result] : @[];
  }
  [matchedElements addObjectsFromArray:query.allElementsBoundByIndex];
  if (matchedElements.count <= 1) {
    // There is no need to sort elements if count of matches is not greater than one
    return matchedElements.copy;
  }
  NSMutableArray<XCUIElement *> *sortedElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    XCUIElement *matchedElement = nil;
    for (XCUIElement *element in matchedElements) {
      if (element.wdUID == snapshot.wdUID) {
        matchedElement = element;
        break;
      }
    }
    if (matchedElement) {
      [sortedElements addObject:matchedElement];
      [matchedElements removeObject:matchedElement];
    }
  }];
  return sortedElements.copy;
}

- (BOOL)fb_waitUntilSnapshotIsStable
{
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  [[XCAXClient_iOS sharedClient] notifyWhenNoAnimationsAreActiveForApplication:self.application reply:^{dispatch_semaphore_signal(sem);}];
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(FBANIMATION_TIMEOUT * NSEC_PER_SEC));
  BOOL result = 0 == dispatch_semaphore_wait(sem, timeout);
  if (!result) {
    [FBLogger logFmt:@"There are still some active animations in progress after %.2f seconds timeout. Visibility detection may cause unexpected delays.", FBANIMATION_TIMEOUT];
  }
  return result;
}

- (NSData *)fb_screenshotWithError:(NSError **)error
{
  if (CGRectIsEmpty(self.frame)) {
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:@"Cannot get a screenshot of zero-sized element"] build];
    }
    return nil;
  }

  Class xcScreenClass = objc_lookUpClass("XCUIScreen");
  if (nil == xcScreenClass) {
    if (error) {
      *error = [[FBErrorBuilder.builder withDescription:@"Element screenshots are only available since Xcode9 SDK"] build];
    }
    return nil;
  }

  XCUIScreen *mainScreen = (XCUIScreen *)[xcScreenClass mainScreen];
  NSData *result = [mainScreen screenshotDataForQuality:1 rect:self.frame error:error];
  if (nil == result) {
    return nil;
  }

  UIImage *image = [UIImage imageWithData:result];
  UIInterfaceOrientation orientation = self.application.interfaceOrientation;
  UIImageOrientation imageOrientation = UIImageOrientationUp;
  // The received element screenshot will be rotated, if the current interface orientation differs from portrait, so we need to fix that first
  if (orientation == UIInterfaceOrientationLandscapeRight) {
    imageOrientation = UIImageOrientationLeft;
  } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
    imageOrientation = UIImageOrientationRight;
  } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
    imageOrientation = UIImageOrientationDown;
  }
  CGSize size = image.size;
  UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
  [[UIImage imageWithCGImage:(CGImageRef)[image CGImage] scale:1.0 orientation:imageOrientation] drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // The resulting data is a JPEG image, so we need to convert it to PNG representation
  return (NSData *)UIImagePNGRepresentation(fixedImage);
}

@end
