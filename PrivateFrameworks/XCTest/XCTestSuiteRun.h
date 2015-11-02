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

#import <XCTWebDriverAgentLib/XCTestRun.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCTestSuiteRun : XCTestRun {
#ifndef __OBJC2__
@private
#if XCT_GENERICS_AVAILABLE
  NSMutableArray<XCTestRun *> *_testRuns;
#else
  NSMutableArray *_testRuns;
#endif
#endif
}

#if XCT_GENERICS_AVAILABLE
@property (atomic, copy, readonly) NSArray<XCTestRun *> *testRuns;
#else
@property (atomic, copy, readonly) NSArray *testRuns;
#endif

- (void)addTestRun:(XCTestRun *)testRun;

@end

@interface XCTestSuiteRun ()

- (void)recordFailureWithDescription:(id)arg1 inFile:(id)arg2 atLine:(unsigned long long)arg3 expected:(_Bool)arg4;
- (double)testDuration;
- (unsigned long long)unexpectedExceptionCount;
- (unsigned long long)failureCount;
- (unsigned long long)executionCount;
- (void)stop;
- (void)start;
- (void)dealloc;
- (id)initWithTest:(id)arg1;

@end

NS_ASSUME_NONNULL_END
