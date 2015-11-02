/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

@class NSArray, XCTestContextScope;

@interface XCTestContext : NSObject
{
    _Bool _didHandleUIInterruption;
    XCTestContextScope *_currentScope;
}

+ (CDUnknownBlockType)defaultAsynchronousUIElementHandler;
@property (atomic, assign) _Bool didHandleUIInterruption; // @synthesize didHandleUIInterruption=_didHandleUIInterruption;
@property (retain, nonatomic) XCTestContextScope *currentScope;
- (_Bool)handleAsynchronousUIElement:(id)arg1;
- (void)removeUIInterruptionMonitor:(id)arg1;
- (id)addUIInterruptionMonitorWithDescription:(id)arg1 handler:(CDUnknownBlockType)arg2;
- (void)performInScope:(CDUnknownBlockType)arg1;
@property (atomic, copy, readonly) NSArray *handlers;
- (id)init;
- (void)dealloc;

@end
