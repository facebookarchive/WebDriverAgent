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

@class NSString, XCTestRun;

NS_ASSUME_NONNULL_BEGIN

@class XCTestRun;

/*!
 * @class XCTest
 *
 * An abstract base class for testing. XCTestCase and XCTestSuite extend XCTest to provide
 * for creating, managing, and executing tests. Most developers will not need to subclass
 * XCTest directly.
 */
@interface XCTest : NSObject {
#ifndef __OBJC2__
@private
  id _internal;
#endif
}

/*!
 * @property (atomic, assign) testCaseCount
 * Number of test cases. Must be overridden by subclasses.
 */
@property (atomic, readonly) NSUInteger testCaseCount;

/*!
 * @property (atomic, assign) name
 * Test's name. Must be overridden by subclasses.
 */
@property (atomic, copy, readonly) NSString *name;

/*!
 * @property (atomic, assign) testRunClass
 * The XCTestRun subclass that will be instantiated when the test is run to hold
 * the test's results. Must be overridden by subclasses.
 */
@property (atomic, readonly) Class testRunClass;

/*!
 * @property (atomic, assign) testRun
 * The test run object that executed the test, an instance of testRunClass. If the test has not yet been run, this will be nil.
 */
#if XCT_NULLABLE_AVAILABLE
@property (atomic, readonly, nullable) XCTestRun *testRun;
#else
@property (atomic, readonly) XCTestRun *testRun;
#endif

/*!
 * @method -performTest:
 * The method through which tests are executed. Must be overridden by subclasses.
 */
- (void)performTest:(XCTestRun *)run;

/*!
 * @method -run
 * Deprecated: use -runTest instead.
 */
- (XCTestRun *)run DEPRECATED_ATTRIBUTE;

/*!
 * @method -runTest
 * Creates an instance of the testRunClass and passes it as a parameter to -performTest:.
 */
- (void)runTest;

/*!
 * @method -setUp
 * Setup method called before the invocation of each test method in the class.
 */
- (void)setUp;

/*!
 * @method -tearDown
 * Teardown method called after the invocation of each test method in the class.
 */
- (void)tearDown;

@end

@interface XCTest ()
{
  id _internal;
}

+ (id)languageAgnosticTestClassNameForTestClass:(Class)arg1;
@property (atomic, copy, readonly) NSString *nameForLegacyLogging;
@property (atomic, copy, readonly) NSString *languageAgnosticTestMethodName;
@property (atomic, copy, readonly) NSString *languageAgnosticTestClassName;
@property (atomic, readonly) XCTestRun *testRun;
@property (atomic, readonly) Class testRunClass;
@property (atomic, readonly) Class _requiredTestRunBaseClass;
@property (atomic, copy, readonly) NSString *name;
@property (atomic, readonly) unsigned long long testCaseCount;

- (void)tearDown;
- (void)setUp;
- (void)runTest;
- (id)run;
- (void)performTest:(id)arg1;
- (id)init;
- (void)dealloc;

@end

NS_ASSUME_NONNULL_END
