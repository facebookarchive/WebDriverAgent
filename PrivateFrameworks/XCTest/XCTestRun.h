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
// Copyright (c) 1997-2005, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the following license:
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL Sente SA OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Note: this license is equivalent to the FreeBSD license.
//
// This notice may not be removed from this file.

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class XCTestRun
 * A test run collects information about the execution of a test. Failures in explicit
 * test assertions are classified as "expected", while failures from unrelated or
 * uncaught exceptions are classified as "unexpected".
 */
@interface XCTestRun : NSObject {
#ifndef __OBJC2__
@private
  id _internalTestRun;
#endif
}

/*!
 * @method +testRunWithTest:
 * Class factory method for the XCTestRun class.
 *
 * @param test An XCTest instance.
 *
 * @return A test run for the provided test.
 */
+ (instancetype)testRunWithTest:(XCTest *)test;

/*!
 * @method -initWithTest:
 * Designated initializer for the XCTestRun class.
 *
 * @param test An XCTest instance.
 *
 * @return A test run for the provided test.
 */
- (instancetype)initWithTest:(XCTest *)test NS_DESIGNATED_INITIALIZER;

/*!
 * @property (atomic, assign) test
 * The test instance provided when the test run was initialized.
 */
@property (atomic, strong, readonly) XCTest *test;

/*!
 * @method -start
 * Start a test run. Must not be called more than once.
 */
- (void)start;

/*!
 * @method -stop
 * Stop a test run. Must not be called unless the run has been started. Must not be called more than once.
 */
- (void)stop;

/*!
 * @property (atomic, assign) startDate
 * The time at which the test run was started, or nil.
 */
#if XCT_NULLABLE_AVAILABLE
@property (atomic, copy, readonly, nullable) NSDate *startDate;
#else
@property (atomic, copy, readonly) NSDate *startDate;
#endif

/*!
 * @property (atomic, assign) stopDate
 * The time at which the test run was stopped, or nil.
 */
#if XCT_NULLABLE_AVAILABLE
@property (atomic, copy, readonly, nullable) NSDate *stopDate;
#else
@property (atomic, copy, readonly) NSDate *stopDate;
#endif

/*!
 * @property (atomic, assign) totalDuration
 * The number of seconds that elapsed between when the run was started and when it was stopped.
 */
@property (atomic, readonly) NSTimeInterval totalDuration;

/*!
 * @property (atomic, assign) testDuration
 * The number of seconds that elapsed between when the run was started and when it was stopped.
 */
@property (atomic, readonly) NSTimeInterval testDuration;

/*!
 * @property (atomic, assign) testCaseCount
 * The number of tests in the run.
 */
@property (atomic, readonly) NSUInteger testCaseCount;

/*!
 * @property (atomic, assign) executionCount
 * The number of test executions recorded during the run.
 */
@property (atomic, readonly) NSUInteger executionCount;

/*!
 * @property (atomic, assign) failureCount
 * The number of test failures recorded during the run.
 */
@property (atomic, readonly) NSUInteger failureCount;

/*!
 * @property (atomic, assign) unexpectedExceptionCount
 * The number of uncaught exceptions recorded during the run.
 */
@property (atomic, readonly) NSUInteger unexpectedExceptionCount;

/*!
 * @property (atomic, assign) totalFailureCount
 * The total number of test failures and uncaught exceptions recorded during the run.
 */
@property (atomic, readonly) NSUInteger totalFailureCount;

/*!
 * @property (atomic, assign) hasSucceeded
 * YES if all tests in the run completed their execution without recording any failures, otherwise NO.
 */
@property (atomic, readonly) BOOL hasSucceeded;

/*!
 * @method -recordFailureWithDescription:inFile:atLine:expected:
 * Records a failure in the execution of the test for this test run. Must not be called
 * unless the run has been started. Must not be called if the test run has been stopped.
 *
 * @param description The description of the failure being reported.
 *
 * @param filePath The file path to the source file where the failure being reported
 * was encountered or nil if unknown.
 *
 * @param lineNumber The line number in the source file at filePath where the
 * failure being reported was encountered.
 *
 * @param expected YES if the failure being reported was the result of a failed assertion,
 * NO if it was the result of an uncaught exception.
 *
 */
#if XCT_NULLABLE_AVAILABLE
- (void)recordFailureWithDescription:(NSString *)description inFile:(nullable NSString *)filePath atLine:(NSUInteger)lineNumber expected:(BOOL)expected;
#else
- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)filePath atLine:(NSUInteger)lineNumber expected:(BOOL)expected;
#endif

@end

@interface XCTestRun ()
{
  id _internalTestRun;
}
@property (atomic, readonly) _XCInternalTestRun *implementation;

@end

NS_ASSUME_NONNULL_END
