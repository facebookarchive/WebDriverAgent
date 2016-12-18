/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCUIElement.h>
#import "XCEventGenerator.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^eventGenerationBlock)(XCEventGenerator *eventGenerator, XCEventGeneratorHandler handlerBlock);

@interface XCUIElement (FBTap)

/**
 Waits for element to become stable (not move) and performs sync tap on element

 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return YES if the operation succeeds, otherwise NO.
*/
- (BOOL)fb_tapWithError:(NSError **)error;

/**
 CBX Additions
 */
- (BOOL)tapAtCoordinate:(CGPoint)point withError:(NSError * _Nullable __autoreleasing *)error;

//TODO: Move this somewhere more general
- (BOOL)generateEvent:(eventGenerationBlock)eventBlock error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
