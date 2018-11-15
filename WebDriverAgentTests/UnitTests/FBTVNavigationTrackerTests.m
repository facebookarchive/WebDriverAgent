/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>
#import "XCUIElementDouble.h"
#import "FBTVNavigationTracker.h"
#import <objc/runtime.h>

@implementation FBTVNavigationTracker (FBTVNavigationTrackerTests)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];
    
    SEL originalSelector = @selector(focusedElement);
    SEL swizzledSelector = @selector(testFocusedElement);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
      class_replaceMethod(class, swizzledSelector,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

#pragma mark - Method Swizzling

- (id<FBElement>)testFocusedElement {
  XCUIElementDouble *focused = XCUIElementDouble.new;
  focused.wdFrame = CGRectMake(100, 100,  100, 100);;
  return focused;
}

@end

@interface FBTVNavigationTrackerTests : XCTestCase
@end

@implementation FBTVNavigationTrackerTests

- (void)testSimpleLeftNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(0, 100,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionLeft);
}

- (void)testSimpleRightNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(200, 100,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionRight);
}

- (void)testSimpleUpNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(100, 0,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionUp);
}

- (void)testSimpleDownNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(100, 200,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionDown);
}

- (void)testComplexLeftNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(0, 50,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionLeft);
}

- (void)testComplexRightNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(200, 50,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionRight);
}

- (void)testComplexUpNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(50, 0,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionUp);
}

- (void)testComplexDownNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(50, 200,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionDown);
}

- (void)testOneDirectionSimpleNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(0, 100,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionLeft);
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionNone);
}

- (void)testOneDirectionComplexWhereXGraterNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(0, 50,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionLeft);
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionUp);
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionNone);
}

- (void)testOneDirectionComplexWhereYGraterNavigation {
  XCUIElementDouble *targetElement = XCUIElementDouble.new;
  targetElement.wdFrame = CGRectMake(50, 0,  100, 100);
  FBTVNavigationTracker *tracker = [FBTVNavigationTracker trackerWithTargetElement:targetElement];
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionUp);
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionLeft);
  XCTAssertEqual(tracker.directionToMoveFocuse, FBTVDirectionNone);
}


@end
