/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBExceptionHandler.h"
#import "FBClassChainQueryParser.h"
#import "FBErrorBuilder.h"
#import "FBElementTypeTransformer.h"
#import "FBPredicate.h"
#import "NSPredicate+FBFormat.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBBaseClassChainToken : NSObject

@property (nonatomic) NSString *asString;
@property (nonatomic) NSUInteger previousItemsCountToOverride;

@end


@interface FBClassNameToken : FBBaseClassChainToken

@end

@interface FBStarToken : FBBaseClassChainToken

@end

@interface FBDescendantMarkerToken : FBBaseClassChainToken

@end

@interface FBSplitterToken : FBBaseClassChainToken

@end

@interface FBOpeningBracketToken : FBBaseClassChainToken

@end

@interface FBClosingBracketToken : FBBaseClassChainToken

@end

@interface FBNumberToken : FBBaseClassChainToken

@end

@interface FBAbstractPredicateToken : FBBaseClassChainToken

@property (nonatomic) BOOL isParsingCompleted;

+ (NSString *)enclosingMarker;

@end

@interface FBSelfPredicateToken : FBAbstractPredicateToken

@end

@interface FBDescendantPredicateToken : FBAbstractPredicateToken

@end

NS_ASSUME_NONNULL_END


@implementation FBBaseClassChainToken

- (id)init
{
  self = [super init];
  if (self) {
    _asString = @"";
    _previousItemsCountToOverride = 0;
  }
  return self;
}

- (instancetype)initWithStringValue:(NSString *)stringValue
{
  self = [super init];
  if (self) {
    _asString = stringValue;
  }
  return self;
}

+ (NSCharacterSet *)allowedCharacters
{
  // This method is expected to be overriden by subclasses
  return [NSCharacterSet characterSetWithCharactersInString:@""];
}

+ (NSUInteger)maxLength
{
  // This method is expected to be overriden by subclasses
  return ULONG_MAX;
}

- (NSArray<Class> *)followingTokens
{
  // This method is expected to be overriden by subclasses
  return @[];
}

+ (BOOL)canConsumeCharacter:(unichar)character
{
  return [self.allowedCharacters characterIsMember:character];
}

- (void)appendChar:(unichar)character
{
  NSMutableString *value = [NSMutableString stringWithString:self.asString];
  [value appendFormat:@"%C", character];
  self.asString = value.copy;;
}

- (nullable FBBaseClassChainToken*)followingTokenBasedOn:(unichar)character
{
  for (Class matchingTokenClass in self.followingTokens) {
    if ([matchingTokenClass canConsumeCharacter:character]) {
      return [[[matchingTokenClass alloc] init] nextTokenWithCharacter:character];
    }
  }
  return nil;
}

- (nullable FBBaseClassChainToken*)nextTokenWithCharacter:(unichar)character
{
  if ([self.class canConsumeCharacter:character] && self.asString.length < [self.class maxLength]) {
    [self appendChar:character];
    return self;
  }
  return [self followingTokenBasedOn:character];
}

@end


@implementation FBClassNameToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet letterCharacterSet];
}

- (NSArray<Class> *)followingTokens
{
  return @[FBSplitterToken.class, FBOpeningBracketToken.class];
}

@end

static NSString *const STAR_TOKEN = @"*";
@implementation FBStarToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet characterSetWithCharactersInString:STAR_TOKEN];
}

- (NSArray<Class> *)followingTokens
{
  return @[FBSplitterToken.class, FBOpeningBracketToken.class];
}

- (nullable FBBaseClassChainToken*)nextTokenWithCharacter:(unichar)character
{
  if ([self.class.allowedCharacters characterIsMember:character]) {
    if (self.asString.length >= 1) {
      FBDescendantMarkerToken *nextToken = [[FBDescendantMarkerToken alloc] initWithStringValue:[NSString stringWithFormat:@"%@%@", STAR_TOKEN, STAR_TOKEN]];
      nextToken.previousItemsCountToOverride = 1;
      return nextToken;
    }
    [self appendChar:character];
    return self;
  }
  return [self followingTokenBasedOn:character];
}

@end


static NSString *const DESCENDANT_MARKER = @"**/";
@implementation FBDescendantMarkerToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet characterSetWithCharactersInString:@"*/"];
}

- (NSArray<Class> *)followingTokens
{
  return @[FBClassNameToken.class, FBStarToken.class];
}

+ (NSUInteger)maxLength
{
  return 3;
}

- (nullable FBBaseClassChainToken*)nextTokenWithCharacter:(unichar)character
{
  if ([self.class.allowedCharacters characterIsMember:character] && self.asString.length <= self.class.maxLength) {
    if (self.asString.length > 0 && ![DESCENDANT_MARKER hasPrefix:self.asString]) {
      return nil;
    }
    if (self.asString.length < self.class.maxLength) {
      [self appendChar:character];
      return self;
    }
  }
  return [self followingTokenBasedOn:character];
}

@end


@implementation FBSplitterToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet characterSetWithCharactersInString:@"/"];
}

- (NSArray<Class> *)followingTokens
{
  return @[FBStarToken.class, FBClassNameToken.class];
}

+ (NSUInteger)maxLength
{
  return 1;
}

@end


@implementation FBOpeningBracketToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet characterSetWithCharactersInString:@"["];
}

- (NSArray<Class> *)followingTokens
{
  return @[FBNumberToken.class, FBSelfPredicateToken.class, FBDescendantPredicateToken.class];
}

+ (NSUInteger)maxLength
{
  return 1;
}

@end


@implementation FBNumberToken

+ (NSCharacterSet *)allowedCharacters
{
  NSMutableCharacterSet *result = [NSMutableCharacterSet new];
  [result formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
  [result addCharactersInString:@"-"];
  return result.copy;
}

- (NSArray<Class> *)followingTokens
{
  return @[FBClosingBracketToken.class];
}

@end


@implementation FBClosingBracketToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet characterSetWithCharactersInString:@"]"];
}

- (NSArray<Class> *)followingTokens
{
  return @[FBSplitterToken.class, FBOpeningBracketToken.class];
}

+ (NSUInteger)maxLength
{
  return 1;
}

@end

static NSString *const FBAbstractMethodInvocationException = @"FBAbstractMethodInvocationException";

@implementation FBAbstractPredicateToken

- (id)init
{
  self = [super init];
  if (self) {
    _isParsingCompleted = NO;
  }
  return self;
}

+ (NSString *)enclosingMarker
{
  NSString *errMsg = [NSString stringWithFormat:@"The + (NSString *)enclosingMarker method is expected to be overriden by %@ class", NSStringFromClass(self.class)];
  @throw [NSException exceptionWithName:FBAbstractMethodInvocationException reason:errMsg userInfo:nil];
}

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet illegalCharacterSet].invertedSet;
}

- (NSArray<Class> *)followingTokens
{
  return @[FBClosingBracketToken.class];
}

+ (BOOL)canConsumeCharacter:(unichar)character
{
  return [[NSCharacterSet characterSetWithCharactersInString:self.class.enclosingMarker] characterIsMember:character];
}

- (void)stripLastChar
{
  if (self.asString.length > 0) {
    self.asString = [self.asString substringToIndex:self.asString.length - 1];
  }
}

- (nullable FBBaseClassChainToken*)nextTokenWithCharacter:(unichar)character
{
  NSString *currentChar = [NSString stringWithFormat:@"%C", character];
  if (!self.isParsingCompleted && [self.class.allowedCharacters characterIsMember:character]) {
    if (0 == self.asString.length) {
      if ([self.class.enclosingMarker isEqualToString:currentChar]) {
        // Do not include enclosing character
        return self;
      }
    } else if ([self.class.enclosingMarker isEqualToString:currentChar]) {
      [self appendChar:character];
      self.isParsingCompleted = YES;
      return self;
    }
    [self appendChar:character];
    return self;
  }
  if (self.isParsingCompleted) {
    if ([currentChar isEqualToString:self.class.enclosingMarker]) {
      // Escaped enclosing character has been detected. Do not finish parsing
      self.isParsingCompleted = NO;
      return self;
    } else {
      // Do not include enclosing character
      [self stripLastChar];
    }
  }
  return [self followingTokenBasedOn:character];
}

@end

@implementation FBSelfPredicateToken

+ (NSString *)enclosingMarker
{
  return @"`";
}

@end

@implementation FBDescendantPredicateToken

+ (NSString *)enclosingMarker
{
  return @"$";
}

@end


@implementation FBClassChainItem

- (instancetype)initWithType:(XCUIElementType)type position:(NSInteger)position predicates:(NSArray<FBAbstractPredicateItem *> *)predicates isDescendant:(BOOL)isDescendant
{
  self = [super init];
  if (self) {
    _type = type;
    _position = position;
    _predicates = predicates;
    _isDescendant = isDescendant;
  }
  return self;
}

@end


@implementation FBClassChain

- (instancetype)initWithElements:(NSArray<FBClassChainItem *> *)elements
{
  self = [super init];
  if (self) {
    _elements = elements;
  }
  return self;
}

@end


@implementation FBClassChainQueryParser

static NSNumberFormatter *numberFormatter = nil;

+ (void)initialize {
  if (nil == numberFormatter) {
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  }
}

+ (NSError *)tokenizationErrorWithIndex:(NSUInteger)index originalQuery:(NSString *)originalQuery
{
  NSString *description = [NSString stringWithFormat:@"Cannot parse class chain query '%@'. Unexpected character detected at position %@:\n%@ <----", originalQuery, @(index + 1), [originalQuery substringToIndex:index + 1]];
  return [[FBErrorBuilder.builder withDescription:description] build];
}

+ (nullable NSArray<FBBaseClassChainToken *> *)tokenizedQueryWithQuery:(NSString*)classChainQuery error:(NSError **)error
{
  NSUInteger queryStringLength = classChainQuery.length;
  FBBaseClassChainToken *token;
  unichar firstCharacter = [classChainQuery characterAtIndex:0];
  if ([classChainQuery hasPrefix:DESCENDANT_MARKER]) {
    token = [[FBDescendantMarkerToken alloc] initWithStringValue:DESCENDANT_MARKER];
  } else if ([FBClassNameToken canConsumeCharacter:firstCharacter]) {
    token = [[FBClassNameToken alloc] initWithStringValue:[NSString stringWithFormat:@"%C", firstCharacter]];
  } else if ([FBStarToken canConsumeCharacter:firstCharacter]) {
    token = [[FBStarToken alloc] initWithStringValue:[NSString stringWithFormat:@"%C", firstCharacter]];
  } else {
    if (error) {
      *error = [self.class tokenizationErrorWithIndex:0 originalQuery:classChainQuery];
    }
    return nil;
  }
  NSMutableArray *result = [NSMutableArray array];
  FBBaseClassChainToken *nextToken = token;
  for (NSUInteger charIdx = token.asString.length; charIdx < queryStringLength; ++charIdx) {
    nextToken = [token nextTokenWithCharacter:[classChainQuery characterAtIndex:charIdx]];
    if (nil == nextToken) {
      if (error) {
        *error = [self.class tokenizationErrorWithIndex:charIdx originalQuery:classChainQuery];
      }
      return nil;
    }
    if (nextToken != token) {
      [result addObject:token];
      if (nextToken.previousItemsCountToOverride > 0 && result.count > 0) {
        NSUInteger itemsCountToOverride = nextToken.previousItemsCountToOverride <= result.count ? nextToken.previousItemsCountToOverride : result.count;
        [result removeObjectsInRange:NSMakeRange(result.count - itemsCountToOverride, itemsCountToOverride)];
      }
      token = nextToken;
    }
  }
  if (nextToken) {
    if (nextToken.previousItemsCountToOverride > 0 && result.count > 0) {
      NSUInteger itemsCountToOverride = nextToken.previousItemsCountToOverride <= result.count ? nextToken.previousItemsCountToOverride : result.count;
      [result removeObjectsInRange:NSMakeRange(result.count - itemsCountToOverride, itemsCountToOverride)];
    }
    [result addObject:nextToken];
  }
  
  FBBaseClassChainToken *lastToken = [result lastObject];
  if (!([lastToken isKindOfClass:FBClosingBracketToken.class] ||
        [lastToken isKindOfClass:FBClassNameToken.class] ||
        [lastToken isKindOfClass:FBStarToken.class])) {
    if (error) {
      *error = [self.class tokenizationErrorWithIndex:queryStringLength - 1 originalQuery:classChainQuery];
    }
    return nil;
  }
  
  return result.copy;
}

+ (NSError *)compilationErrorWithQuery:(NSString *)originalQuery description:(NSString *)description
{
  NSString *fullDescription = [NSString stringWithFormat:@"Cannot parse class chain query '%@'. %@", originalQuery, description];
  return [[FBErrorBuilder.builder withDescription:fullDescription] build];
}

+ (nullable FBClassChain*)compiledQueryWithTokenizedQuery:(NSArray<FBBaseClassChainToken *> *)tokenizedQuery originalQuery:(NSString *)originalQuery error:(NSError **)error
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType chainElementType = XCUIElementTypeAny;
  int chainElementPosition = 1;
  BOOL isTypeSet = NO;
  BOOL isPositionSet = NO;
  BOOL isDescendantSet = NO;
  NSMutableArray<FBAbstractPredicateItem *> *predicates = [NSMutableArray array];
  for (FBBaseClassChainToken *token in tokenizedQuery) {
    if ([token isKindOfClass:FBClassNameToken.class]) {
      if (isTypeSet) {
        NSString *description = [NSString stringWithFormat:@"Unexpected token '%@'. The type name can be set only once.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      @try {
        chainElementType = [FBElementTypeTransformer elementTypeWithTypeName:token.asString];
        isTypeSet = YES;
      } @catch (NSException *e) {
        if ([e.name isEqualToString:FBInvalidArgumentException]) {
          NSString *description = [NSString stringWithFormat:@"'%@' class name is unknown to WDA", token.asString];
          *error = [self.class compilationErrorWithQuery:originalQuery description:description];
          return nil;
        }
        @throw e;
      }
    } else if ([token isKindOfClass:FBStarToken.class]) {
      if (isTypeSet) {
        NSString *description = [NSString stringWithFormat:@"Unexpected token '%@'. The type name can be set only once.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      chainElementType = XCUIElementTypeAny;
      isTypeSet = YES;
    } else if ([token isKindOfClass:FBDescendantMarkerToken.class]) {
      if (isDescendantSet) {
        NSString *description = [NSString stringWithFormat:@"Unexpected token '%@'. Descendant markers cannot be duplicated.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      isTypeSet = NO;
      isPositionSet = NO;
      [predicates removeAllObjects];
      isDescendantSet = YES;
    } else if ([token isKindOfClass:FBAbstractPredicateToken.class]) {
      if (isPositionSet) {
        NSString *description = [NSString stringWithFormat:@"Predicate value '%@' must be set before position value.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      if (!((FBAbstractPredicateToken *)token).isParsingCompleted) {
        NSString *description = [NSString stringWithFormat:@"Cannot find the end of '%@' predicate value.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      NSPredicate *value = [NSPredicate fb_formatSearchPredicate:[FBPredicate predicateWithFormat:token.asString]];
      if ([token isKindOfClass:FBSelfPredicateToken.class]) {
        [predicates addObject:[[FBSelfPredicateItem alloc] initWithValue:value]];
      } else if ([token isKindOfClass:FBDescendantPredicateToken.class]) {
        [predicates addObject:[[FBDescendantPredicateItem alloc] initWithValue:value]];
      }
    } else if ([token isKindOfClass:FBNumberToken.class]) {
      if (isPositionSet) {
        NSString *description = [NSString stringWithFormat:@"Position value '%@' is expected to be set only once.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      NSNumber *position = [numberFormatter numberFromString:token.asString];
      if (nil == position || 0 == position.intValue) {
        NSString *description = [NSString stringWithFormat:@"Position value '%@' is expected to be a valid integer number not equal to zero.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      chainElementPosition = [position intValue];
      isPositionSet = YES;
    } else if ([token isKindOfClass:FBSplitterToken.class]) {
      if (!isPositionSet) {
        chainElementPosition = 1;
      }
      if (isDescendantSet) {
        if (isTypeSet) {
          [result addObject:[[FBClassChainItem alloc] initWithType:chainElementType position:chainElementPosition predicates:predicates.copy isDescendant:YES]];
          isDescendantSet = NO;
        }
      } else {
        [result addObject:[[FBClassChainItem alloc] initWithType:chainElementType position:chainElementPosition predicates:predicates.copy isDescendant:NO]];
      }
      isTypeSet = NO;
      isPositionSet = NO;
      [predicates removeAllObjects];
    }
  }
  if (!isPositionSet) {
    // pick all siblings by default for the last item in the chain
    chainElementPosition = 0;
  }
  if (isDescendantSet) {
    if (isTypeSet) {
      [result addObject:[[FBClassChainItem alloc] initWithType:chainElementType position:chainElementPosition predicates:predicates.copy isDescendant:YES]];
    } else {
      NSString *description = @"Descendants lookup modifier '**/' should be followed with the actual element type";
      *error = [self.class compilationErrorWithQuery:originalQuery description:description];
      return nil;
    }
  } else {
    [result addObject:[[FBClassChainItem alloc] initWithType:chainElementType position:chainElementPosition predicates:predicates.copy isDescendant:NO]];
  }
  return [[FBClassChain alloc] initWithElements:result.copy];
}

+ (FBClassChain *)parseQuery:(NSString*)classChainQuery error:(NSError **)error
{
  NSAssert(classChainQuery.length > 0, @"Query length should be greater than zero", nil);
  NSArray *tokenizedQuery = [self.class tokenizedQueryWithQuery:classChainQuery error:error];
  if (nil == tokenizedQuery) {
    return nil;
  }
  return [self.class compiledQueryWithTokenizedQuery:tokenizedQuery originalQuery:classChainQuery error:error];
}

@end


@implementation FBAbstractPredicateItem

- (instancetype)initWithValue:(NSPredicate *)value
{
  self = [super init];
  if (self) {
    _value = value;
  }
  return self;
}

@end

@implementation FBSelfPredicateItem

@end

@implementation FBDescendantPredicateItem

@end
