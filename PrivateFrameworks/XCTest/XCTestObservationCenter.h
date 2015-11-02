/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

//
// Copyright (c) 2013-2015 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <XCTWebDriverAgentLib/XCTestObservation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class XCTestObservationCenter
 *
 * The XCTestObservationCenter distributes information about the progress of test runs to registered observers. Observers
 * can be any object conforming to the XCTestObservation protocol.
 */
@interface XCTestObservationCenter : NSObject {
#ifndef __OBJC2__
@private
  id _internalImplementation;
#endif
}

/*!
 * @method +sharedTestObservationCenter
 *
 * @return The shared XCTestObservationCenter singleton instance.
 */
+ (XCTestObservationCenter *)sharedTestObservationCenter;

/*!
 * @method -addTestObserver:
 *
 * Register an object conforming to XCTestObservation as an observer for the current test session. Observers may be added
 * at any time, but will not receive events that occurred before they were registered. The observation center maintains a strong
 * reference to observers.
 *
 * Events may be delivered to observers in any order - given observers A and B, A may be notified of a test failure before
 * or after B. Any ordering dependencies or serialization requirements must be managed by clients.
 */
- (void)addTestObserver:(id<XCTestObservation>)testObserver;

/*!
 * @method -removeTestObserver:
 *
 * Unregister an object conforming to XCTestObservation as an observer for the current test session.
 */
- (void)removeTestObserver:(id<XCTestObservation>)testObserver;

@end

@interface XCTestObservationCenter ()
@property (atomic, assign) _Bool suspended;
@property (atomic, readonly) NSMutableSet *observers;

- (void)_testCase:(id)arg1 didFinishActivity:(id)arg2;
- (void)_testCase:(id)arg1 willStartActivity:(id)arg2;
- (void)_testCaseDidFail:(id)arg1 withDescription:(id)arg2 inFile:(id)arg3 atLine:(unsigned long long)arg4;
- (void)_testCase:(id)arg1 didMeasureValues:(id)arg2 forPerformanceMetricID:(id)arg3 name:(id)arg4 unitsOfMeasurement:(id)arg5 baselineName:(id)arg6 baselineAverage:(id)arg7 maxPercentRegression:(id)arg8 maxPercentRelativeStandardDeviation:(id)arg9 maxRegression:(id)arg10 maxStandardDeviation:(id)arg11 file:(id)arg12 line:(unsigned long long)arg13;
- (void)_testCaseDidStop:(id)arg1;
- (void)_testCaseDidStart:(id)arg1;
- (void)_testSuiteDidFail:(id)arg1 withDescription:(id)arg2 inFile:(id)arg3 atLine:(unsigned long long)arg4;
- (void)_testSuiteDidStop:(id)arg1;
- (void)_testSuiteDidStart:(id)arg1;
- (void)_suspendObservationForBlock:(CDUnknownBlockType)arg1;
- (void)_suspendObservation;
- (void)_resumeObservation;
- (void)_observeTestExecutionForBlock:(CDUnknownBlockType)arg1;
- (void)_instantiateObserversFromObserverClassNames:(id)arg1;
- (void)_addLegacyTestObserver:(id)arg1;
- (id)description;
- (id)init;

@end

NS_ASSUME_NONNULL_END
