/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTWebDriverAgentLib/XCUIElementTypes.h>
#import <XCTWebDriverAgentLib/XCUIElementTypeQueryProvider.h>
#import <XCTWebDriverAgentLib/CDStructures.h>

@class NSArray, NSOrderedSet, NSString, XCUIApplication, XCUIElement;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const XCUIIdentifierCloseWindow;
extern NSString *const XCUIIdentifierMinimizeWindow;
extern NSString *const XCUIIdentifierZoomWindow;
extern NSString *const XCUIIdentifierFullScreenWindow;

@class XCUIElement;

/*! Object for locating elements that can be chained with other queries. */
NS_CLASS_AVAILABLE(10_11, 9_0)
@interface XCUIElementQuery : NSObject <XCUIElementTypeQueryProvider>

/*! Returns an element that will use the query for resolution. */
@property (atomic, readonly) XCUIElement *element;

/*! Evaluates the query at the time it is called and returns the number of matches found. */
@property (atomic, readonly) NSUInteger count;

/*! Returns an element that will resolve to the index into the query's result set. */
- (XCUIElement *)elementAtIndex:(NSUInteger)index NS_DEPRECATED(10_11, 10_11, 9_0, 9_0, "Use elementBoundByIndex instead.");

/*! Returns an element that will use the index into the query's results to determine which underlying accessibility element it is matched with. */
- (XCUIElement *)elementBoundByIndex:(NSUInteger)index;

/*! Returns an element that matches the predicate. */
- (XCUIElement *)elementMatchingPredicate:(NSPredicate *)predicate;

/*! Returns an element that matches the type and identifier. */
- (XCUIElement *)elementMatchingType:(XCUIElementType)elementType identifier:(nullable NSString *)identifier;

/*! Keyed subscripting is implemented as a shortcut for matching an identifier only. For example, app.descendants["Foo"] -> XCUIElement. */
- (XCUIElement *)objectForKeyedSubscript:(NSString *)key;

/*! Immediately evaluates the query and returns an array of elements bound to the resulting accessibility elements. */
@property (atomic, copy, readonly) NSArray<XCUIElement *> *allElementsBoundByAccessibilityElement;

/*! Immediately evaluates the query and returns an array of elements bound by the index of each result. */
@property (atomic, copy, readonly) NSArray<XCUIElement *> *allElementsBoundByIndex;

/*! Returns a new query that finds the descendants of all the elements found by the receiver. */
- (XCUIElementQuery *)descendantsMatchingType:(XCUIElementType)type;

/*! Returns a new query that finds the direct children of all the elements found by the receiver. */
- (XCUIElementQuery *)childrenMatchingType:(XCUIElementType)type;

/*! Returns a new query that applies the specified attributes or predicate to the receiver. */
- (XCUIElementQuery *)matchingPredicate:(NSPredicate *)predicate;
- (XCUIElementQuery *)matchingType:(XCUIElementType)elementType identifier:(nullable NSString *)identifier;
- (XCUIElementQuery *)matchingIdentifier:(NSString *)identifier;

/*! Returns a new query for finding elements that contain a descendant matching the specification. */
- (XCUIElementQuery *)containingPredicate:(NSPredicate *)predicate;
- (XCUIElementQuery *)containingType:(XCUIElementType)elementType identifier:(nullable NSString *)identifier;

/*!
 @discussion
 Provides debugging information about the query. The data in the string will vary based on the time
 at which it is captured, but it may include any of the following as well as additional data:
 A description of each step of the query.
 Information about the inputs and matched outputs of each step of the query.
 This data should be used for debugging only - depending on any of the data as part of a test is unsupported.
 */
@property (atomic, copy, readonly) NSString *debugDescription;

@end


@interface XCUIElementQuery ()
{
  _Bool _changesScope;
  NSString *_queryDescription;
  XCUIElementQuery *_inputQuery;
  CDUnknownBlockType _filter;
  unsigned long long _expressedType;
  NSArray *_expressedIdentifiers;
  NSOrderedSet *_lastInput;
  NSOrderedSet *_lastOutput;
}

@property (atomic, copy) NSOrderedSet *lastOutput;
@property (atomic, copy) NSOrderedSet *lastInput;
@property (atomic, copy) NSArray *expressedIdentifiers;
@property (atomic, assign) unsigned long long expressedType; // @synthesize expressedType=_expressedType;
@property (atomic, assign) _Bool changesScope; // @synthesize changesScope=_changesScope;
@property (atomic, copy, readonly) CDUnknownBlockType filter;
@property (atomic, readonly) XCUIElementQuery *inputQuery;
@property (atomic, copy, readonly) NSString *queryDescription;
- (id)matchingSnapshotsWithError:(NSError **)arg1;
- (id)matchingSnapshotsHandleUIInterruption:(_Bool)arg1 withError:(NSError **)arg2;
- (id)_elementMatchingAccessibilityElementOfSnapshot:(id)arg1;

- (id)_containingPredicate:(id)arg1 queryDescription:(id)arg2;
- (id)_predicateWithType:(unsigned long long)arg1 identifier:(id)arg2;
- (id)_queryWithPredicate:(id)arg1;
- (id)sorted:(CDUnknownBlockType)arg1;
- (id)descending:(unsigned long long)arg1;
- (id)ascending:(unsigned long long)arg1;
- (id)filter:(CDUnknownBlockType)arg1;
//- (id)_debugInfoWithIndent:(id *)arg1;
@property (atomic, copy, readonly) NSString *elementDescription;
- (id)_derivedExpressedIdentifiers;
- (unsigned long long)_derivedExpressedType;
@property (atomic, readonly) XCUIApplication *application;
- (id)initWithInputQuery:(id)arg1 queryDescription:(id)arg2 filter:(CDUnknownBlockType)arg3;
- (void)dealloc;

@end

NS_ASSUME_NONNULL_END
