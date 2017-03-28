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
#import "NSPredicate+FBFormat.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBBaseClassChainToken : NSObject

@property (nonatomic) NSString *asString;

@end


@interface FBClassNameToken : FBBaseClassChainToken

@end

@interface FBStarToken : FBBaseClassChainToken

@end


@interface FBSplitterToken : FBBaseClassChainToken

@end


@interface FBOpeningBracketToken : FBBaseClassChainToken

@end


@interface FBClosingBracketToken : FBBaseClassChainToken

@end


@interface FBNumberToken : FBBaseClassChainToken

@end


@interface FBPredicateToken : FBBaseClassChainToken

@property (nonatomic) BOOL isParsingCompleted;

@end

NS_ASSUME_NONNULL_END


@implementation FBBaseClassChainToken

- (id)init
{
  self = [super init];
  if (self) {
    _asString = @"";
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

- (nullable instancetype)followingTokenBasedOn:(unichar)character
{
  for (Class matchingTokenClass in self.followingTokens) {
    if ([matchingTokenClass canConsumeCharacter:character]) {
      return [[[matchingTokenClass alloc] init] nextTokenWithCharacter:character];
    }
  }
  return nil;
}

- (nullable instancetype)nextTokenWithCharacter:(unichar)character
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


@implementation FBStarToken

+ (NSCharacterSet *)allowedCharacters
{
  return [NSCharacterSet characterSetWithCharactersInString:@"*"];
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
  return @[FBNumberToken.class, FBPredicateToken.class];
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


@implementation FBPredicateToken

static NSString* const ENCLOSING_MARKER = @"`";

- (id)init
{
  self = [super init];
  if (self) {
    _isParsingCompleted = NO;
  }
  return self;
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
  return [[NSCharacterSet characterSetWithCharactersInString:ENCLOSING_MARKER] characterIsMember:character];
}

- (void)stripLastChar
{
  if (self.asString.length > 0) {
    self.asString = [self.asString substringToIndex:self.asString.length - 1];
  }
}

- (nullable instancetype)nextTokenWithCharacter:(unichar)character
{
  NSString *currentChar = [NSString stringWithFormat:@"%C", character];
  if (!self.isParsingCompleted && [self.class.allowedCharacters characterIsMember:character]) {
    if (0 == self.asString.length) {
      if ([ENCLOSING_MARKER isEqualToString:currentChar]) {
        // Do not include enclosing character
        return self;
      }
    } else if ([ENCLOSING_MARKER isEqualToString:currentChar]) {
      [self appendChar:character];
      self.isParsingCompleted = YES;
      return self;
    }
    [self appendChar:character];
    return self;
  }
  if (self.isParsingCompleted) {
    if ([currentChar isEqualToString:ENCLOSING_MARKER]) {
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


@implementation FBClassChainElement

- (instancetype)initWithType:(XCUIElementType)type position:(NSInteger)position predicate:(NSPredicate *)predicate
{
  self = [super init];
  if (self) {
    _type = type;
    _position = position;
    _predicate = predicate;
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
  if ([FBClassNameToken canConsumeCharacter:firstCharacter]) {
    token = [[FBClassNameToken alloc] initWithStringValue:[NSString stringWithFormat:@"%C", firstCharacter]];
  } else if ([FBStarToken canConsumeCharacter:firstCharacter]) {
    token = [[FBStarToken alloc] initWithStringValue:[NSString stringWithFormat:@"%C", firstCharacter]];
  } else {
    *error = [self.class tokenizationErrorWithIndex:0 originalQuery:classChainQuery];
    return nil;
  }
  NSMutableArray *result = [NSMutableArray array];
  FBBaseClassChainToken *nextToken = token;
  for (NSUInteger charIdx = 1; charIdx < queryStringLength; ++charIdx) {
    nextToken = [token nextTokenWithCharacter:[classChainQuery characterAtIndex:charIdx]];
    if (nil == nextToken) {
      *error = [self.class tokenizationErrorWithIndex:charIdx originalQuery:classChainQuery];
      return nil;
    }
    if (nextToken != token) {
      [result addObject:token];
      token = nextToken;
    }
  }
  if (nil != nextToken) {
    [result addObject:nextToken];
  }
  
  for (NSUInteger tokenIdx = 0; tokenIdx < result.count; ++tokenIdx) {
    if ([[result objectAtIndex:tokenIdx] isKindOfClass:FBStarToken.class]) {
      [result replaceObjectAtIndex:tokenIdx withObject:[[FBClassNameToken alloc] initWithStringValue:[FBElementTypeTransformer stringWithElementType:XCUIElementTypeAny]]];
    }
  }
  
  FBBaseClassChainToken *lastToken = [result lastObject];
  if (!([lastToken isKindOfClass:FBClosingBracketToken.class] || [lastToken isKindOfClass:FBClassNameToken.class])) {
    *error = [self.class tokenizationErrorWithIndex:queryStringLength - 1 originalQuery:classChainQuery];
    return nil;
  }
  
  return result.copy;
}

+ (NSError *)compilationErrorWithQuery:(NSString *)originalQuery description:(NSString *)description
{
  NSString *fullDescription = [NSString stringWithFormat:@"Cannot parse class chain query '%@'. %@", originalQuery, description];
  return [[FBErrorBuilder.builder withDescription:fullDescription] build];
}

+ (nullable FBClassChain)compiledQueryWithTokenizedQuery:(NSArray<FBBaseClassChainToken *> *)tokenizedQuery originalQuery:(NSString *)originalQuery error:(NSError **)error
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType chainElementType;
  int chainElementPosition = 1;
  BOOL isPositionSet = NO;
  BOOL isPredicateSet = NO;
  NSPredicate *predicate = nil;
  for (FBBaseClassChainToken *token in tokenizedQuery) {
    if ([token isKindOfClass:FBClassNameToken.class]) {
      @try {
        chainElementType = [FBElementTypeTransformer elementTypeWithTypeName:token.asString];
      } @catch (NSException *e) {
        if ([e.name isEqualToString:FBInvalidArgumentException]) {
          NSString *description = [NSString stringWithFormat:@"'%@' class name is unknown to WDA", token.asString];
          *error = [self.class compilationErrorWithQuery:originalQuery description:description];
          return nil;
        }
        @throw e;
      }
    } else if ([token isKindOfClass:FBPredicateToken.class]) {
      if (isPredicateSet) {
        NSString *description = [NSString stringWithFormat:@"Predicate value '%@' is expected to be set only once.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      if (isPositionSet) {
        NSString *description = [NSString stringWithFormat:@"Predicate value '%@' must be set before position value.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      if (!((FBPredicateToken *)token).isParsingCompleted) {
        NSString *description = [NSString stringWithFormat:@"Cannot find the end of '%@' predicate value.", token.asString];
        *error = [self.class compilationErrorWithQuery:originalQuery description:description];
        return nil;
      }
      predicate = [NSPredicate fb_formatSearchPredicate:[NSPredicate predicateWithFormat:token.asString]];
      isPredicateSet = YES;
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
      [result addObject:[[FBClassChainElement alloc] initWithType:chainElementType position:chainElementPosition predicate:predicate]];
      isPositionSet = NO;
      isPredicateSet = NO;
      predicate = nil;
    }
  }
  if (!isPositionSet) {
    // pick all siblings by default for the last item in the chain
    chainElementPosition = 0;
  }
  [result addObject:[[FBClassChainElement alloc] initWithType:chainElementType position:chainElementPosition predicate:predicate]];
  return result.copy;
}

+ (FBClassChain)parseQuery:(NSString*)classChainQuery error:(NSError **)error
{
  NSAssert(classChainQuery.length > 0, @"Query length should be greater than zero", nil);
  NSArray *tokenizedQuery = [self.class tokenizedQueryWithQuery:classChainQuery error:error];
  if (nil == tokenizedQuery) {
    return nil;
  }
  NSArray *compiledQuery = [self.class compiledQueryWithTokenizedQuery:tokenizedQuery originalQuery:classChainQuery error:error];
  if (nil == compiledQuery) {
    return nil;
  }
  return compiledQuery.copy;
}

@end
