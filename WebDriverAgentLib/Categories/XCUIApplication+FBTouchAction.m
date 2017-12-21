/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "XCUIApplication+FBTouchAction.h"

#import "FBAppiumActionsSynthesizer.h"
#import "FBBaseActionsSynthesizer.h"
#import "FBLogger.h"
#import "FBRunLoopSpinner.h"
#import "FBW3CActionsSynthesizer.h"
#import "FBXCTestDaemonsProxy.h"
#import "XCEventGenerator.h"

@implementation XCUIApplication (FBTouchAction)

- (BOOL)fb_performActionsWithSynthesizerType:(Class)synthesizerType actions:(NSArray *)actions elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error
{
  FBBaseActionsSynthesizer *synthesizer = [[synthesizerType alloc] initWithActions:actions forApplication:self elementCache:elementCache error:error];
  if (nil == synthesizer) {
    return NO;
  }
  XCSynthesizedEventRecord *eventRecord = [synthesizer synthesizeWithError:error];
  if (nil == eventRecord) {
    return NO;
  }
  return [self fb_synthesizeEvent:eventRecord error:error];
}

- (BOOL)fb_performAppiumTouchActions:(NSArray *)actions elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error
{
  return [self fb_performActionsWithSynthesizerType:FBAppiumActionsSynthesizer.class actions:actions elementCache:elementCache error:error];
}

- (BOOL)fb_performW3CTouchActions:(NSArray *)actions elementCache:(nullable FBElementCache *)elementCache error:(NSError **)error
{
  return [self fb_performActionsWithSynthesizerType:FBW3CActionsSynthesizer.class actions:actions elementCache:elementCache error:error];
}

- (BOOL)fb_synthesizeEvent:(XCSynthesizedEventRecord *)event error:(NSError *__autoreleasing*)error
{
  return [FBXCTestDaemonsProxy synthesizeEventWithRecord:event error:error];
}


@end
