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

@interface FBClassChainElement : NSObject

/*! Element's position */
@property (readonly, nonatomic) NSInteger position;
/*! Element's type */
@property (readonly, nonatomic) XCUIElementType type;
/*! Element's predicate */
@property (nullable, readonly, nonatomic) NSPredicate *predicate;

/**
 Instance constructor, which allows to set element type and position
 
 @param type on of supoported element types declared in XCUIElementType enum
 @param position element position relative to its sibling element. Numeration
   starts with 1. Zero value means that all sibling element should be selected.
   Negative value means that numeration starts from the last element, for example
   -1 is the last child element and -2 is the second last element
 @param predicate valid predicate expession for element search. Can be nil
 @return FBClassChainElement instance
 */
- (instancetype)initWithType:(XCUIElementType)type position:(NSInteger)position predicate:(NSPredicate *)predicate;

@end

/*! Type alias for the product of class chain query parsing */
typedef NSArray<FBClassChainElement *> * FBClassChain;

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
+ (nullable FBClassChain)parseQuery:(NSString*)classChainQuery error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
