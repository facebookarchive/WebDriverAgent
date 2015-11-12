// Copyright 2004-present Facebook. All Rights Reserved.

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

#import <XCTWebDriverAgentLib/XCTestObserver.h>

/*!
 * XCTestLog is deprecated.
 */

DEPRECATED_ATTRIBUTE
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface XCTestLog : XCTestObserver
#pragma clang diagnostic pop

@property (atomic, strong, readonly) NSFileHandle *logFileHandle;
- (void)testLogWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)testLogWithFormat:(NSString *)format arguments:(va_list)arguments NS_FORMAT_FUNCTION(1,0);

@end

@interface XCTestLog ()
{
}

+ (id)_messageForTest:(id)arg1 didMeasureValues:(id)arg2 forPerformanceMetricID:(id)arg3 name:(id)arg4 unitsOfMeasurement:(id)arg5 baselineName:(id)arg6 baselineAverage:(id)arg7 maxPercentRegression:(id)arg8 maxPercentRelativeStandardDeviation:(id)arg9 maxRegression:(id)arg10 maxStandardDeviation:(id)arg11 file:(id)arg12 line:(unsigned long long)arg13;
- (void)testCaseDidFail:(id)arg1 withDescription:(id)arg2 inFile:(id)arg3 atLine:(unsigned long long)arg4;
- (void)_testCase:(id)arg1 didMeasureValues:(id)arg2 forPerformanceMetricID:(id)arg3 name:(id)arg4 unitsOfMeasurement:(id)arg5 baselineName:(id)arg6 baselineAverage:(id)arg7 maxPercentRegression:(id)arg8 maxPercentRelativeStandardDeviation:(id)arg9 maxRegression:(id)arg10 maxStandardDeviation:(id)arg11 file:(id)arg12 line:(unsigned long long)arg13;
- (void)testCaseDidStop:(id)arg1;
- (void)testCaseDidStart:(id)arg1;
- (void)testSuiteDidFail:(id)arg1 withDescription:(id)arg2 inFile:(id)arg3 atLine:(unsigned long long)arg4;
- (void)testSuiteDidStop:(id)arg1;
- (void)testSuiteDidStart:(id)arg1;
- (void)_testDidFail:(id)arg1 withDescription:(id)arg2 inFile:(id)arg3 atLine:(unsigned long long)arg4;
- (void)testLogWithFormat:(id)arg1 arguments:(char *)arg2;
- (void)testLogWithFormat:(id)arg1;
@property (atomic, readonly) NSFileHandle *logFileHandle;
- (id)dateFormatter;

@end
