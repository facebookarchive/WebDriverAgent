/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+FBTap.h"

#import "FBRunLoopSpinner.h"
#import "FBLogger.h"
#import "FBMathUtils.h"
#import "XCUIElement+FBUtilities.h"
#import "XCElementSnapshot-Hitpoint.h"
#import "XCEventGenerator.h"
#import "XCSynthesizedEventRecord.h"

@implementation XCUIElement (FBTap)

typedef void(^eventGenerationBlock)(XCEventGenerator *eventGenerator, XCEventGeneratorHandler handlerBlock);

- (BOOL)generateEvent:(eventGenerationBlock)eventBlock error:(NSError * _Nullable __autoreleasing *)error {
    [self fb_waitUntilFrameIsStable];
    __block BOOL didSucceed;
    [FBRunLoopSpinner spinUntilCompletion:^(void(^completion)()){
        XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
            if (commandError) {
                [FBLogger logFmt:@"Failed to perform tap: %@", commandError];
            }
            if (error) {
                *error = commandError;
            }
            didSucceed = (commandError == nil);
            completion();
        };
        eventBlock([XCEventGenerator sharedGenerator], handlerBlock);
    }];
    return didSucceed;
}

- (BOOL)tapAtCoordinate:(CGPoint)point withError:(NSError * _Nullable __autoreleasing *)error {
    return [self generateEvent:^(XCEventGenerator *eventGenerator, XCEventGeneratorHandler handlerBlock) {
        CGPoint hitPoint = FBInvertPointForApplication(point, self.application.frame.size, self.application.interfaceOrientation);
        if ([eventGenerator respondsToSelector:@selector(tapAtTouchLocations:numberOfTaps:orientation:handler:)]) {
            [eventGenerator tapAtTouchLocations:@[[NSValue valueWithCGPoint:hitPoint]]
                                   numberOfTaps:1
                                    orientation:self.interfaceOrientation
                                        handler:handlerBlock];
        } else {
            [eventGenerator tapAtPoint:hitPoint
                           orientation:self.interfaceOrientation
                               handler:handlerBlock];
        }
    } error:error];
}

- (BOOL)fb_tapWithError:(NSError **)error
{
    NSValue *hitpointValue = self.lastSnapshot.suggestedHitpoints.firstObject;
    CGPoint hitPoint = hitpointValue ? hitpointValue.CGPointValue : [self coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)].screenPoint;
    return [self tapAtCoordinate:hitPoint withError:error];
}

@end
