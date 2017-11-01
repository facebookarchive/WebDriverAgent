/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>


NS_ASSUME_NONNULL_BEGIN

@interface FBAbstractPredicateItem : NSObject

/*! The actual predicate value of an item */
@property (nonatomic, readonly) NSPredicate *value;

/**
 Instance constructor, which allows to set item value on instance creation
 
 @param value the actual predicate value
 @return FBAbstractPredicateItem instance
 */
- (instancetype)initWithValue:(NSPredicate *)value;

@end

@interface FBSelfPredicateItem : FBAbstractPredicateItem

@end

@interface FBDescendantPredicateItem : FBAbstractPredicateItem

@end

@interface FBClassChainItem : NSObject

/*! Element's position */
@property (readonly, nonatomic) NSInteger position;
/*! Element's type */
@property (readonly, nonatomic) XCUIElementType type;
/*! Whether an element is a descendant of the previos element */
@property (readonly, nonatomic) BOOL isDescendant;
/*! The ordered list of matching predicates for the current element */
@property (readonly, nonatomic) NSArray<FBAbstractPredicateItem *> *predicates;

/**
 Instance constructor, which allows to set element type and position
 
 @param type on of supoported element types declared in XCUIElementType enum
 @param position element position relative to its sibling element. Numeration
   starts with 1. Zero value means that all sibling element should be selected.
   Negative value means that numeration starts from the last element, for example
   -1 is the last child element and -2 is the second last element
 @param predicates the list of matching descendant/self predicates
 @param isDescendant equals to YES if the element is a descendantt element of
   the previous element in the chain. NO value means the element is the direct
   child of the previous element
 @return FBClassChainElement instance
 */
- (instancetype)initWithType:(XCUIElementType)type position:(NSInteger)position predicates:(NSArray<FBAbstractPredicateItem *> *)predicates isDescendant:(BOOL)isDescendant;

@end

@interface FBClassChain : NSObject

/*! Array of parsed chain items */
@property (readonly, nonatomic, copy) NSArray<FBClassChainItem *> *elements;

/**
 Instance constructor for parsed class chain instance
 
 @param elements an array of parsed chains elements
 @return FBClassChain instance
 */
- (instancetype)initWithElements:(NSArray<FBClassChainItem *> *)elements;

@end

@interface FBClassChainQueryParser : NSObject

/**
 Method used to interpret class chain queries
 
 @param classChainQuery class chain query as string. See the documentation of
   XCUIElement+FBClassChain category for more details about the expected query format
 @param error standard NSError object, which is going to be initializaed if
   there are query parsing errors
 @return list of parsed primitives packed to FBClassChainElement class or nil in case
   there was parsing error (the parameter will be initialized with detailed error description in such case)
 @throws FBUnknownAttributeException if any of predicates in the chain contains unknown attribute 
 */
+ (nullable FBClassChain*)parseQuery:(NSString*)classChainQuery error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
