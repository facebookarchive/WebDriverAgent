/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "XCUIElement+FBFind.h"

#import "FBElementTypeTransformer.h"
#import "XCElementSnapshot.h"
#import "XCElementSnapshot+FBHelpers.h"
#import "XCUIElement+FBWebDriverAttributes.h"

@implementation XCUIElement (FBFind)


#pragma mark - Search by ClassName

- (NSArray<XCUIElement *> *)fb_descendantsMatchingClassName:(NSString *)className
{
  NSMutableArray *result = [NSMutableArray array];
  XCUIElementType type = [FBElementTypeTransformer elementTypeWithTypeName:className];
  if (self.elementType == type || type == XCUIElementTypeAny) {
    [result addObject:self];
  }
  [result addObjectsFromArray:[[self descendantsMatchingType:type] allElementsBoundByIndex]];
  return result.copy;
}

#pragma mark - Search by property value

- (NSArray<XCUIElement *> *)fb_descendantsMatchingProperty:(NSString *)property value:(NSString *)value partialSearch:(BOOL)partialSearch
{
  NSMutableArray *elements = [NSMutableArray array];
  [self descendantsWithProperty:property value:value partial:partialSearch results:elements];
  return elements;
}

- (void)descendantsWithProperty:(NSString *)property value:(NSString *)value partial:(BOOL)partialSearch results:(NSMutableArray<XCUIElement *> *)results
{
  if (partialSearch) {
    NSString *text = [self fb_valueForWDAttributeName:property];
    BOOL isString = [text isKindOfClass:[NSString class]];
    if (isString && [text rangeOfString:value].location != NSNotFound) {
      [results addObject:self];
    }
  } else {
    if ([[self fb_valueForWDAttributeName:property] isEqual:value]) {
      [results addObject:self];
    }
  }

  property = wdAttributeNameForAttributeName(property);
  value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
  NSString *operation = partialSearch ?
  [NSString stringWithFormat:@"%@ like '*%@*'", property, value] :
  [NSString stringWithFormat:@"%@ == '%@'", property, value];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:operation];
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = [query allElementsBoundByIndex];
  [results addObjectsFromArray:childElements];
}


#pragma mark - Search by Predicate String

- (NSArray<XCUIElement *> *)fb_descendantsMatchingPredicate:(NSPredicate *)predicate {
  XCUIElementQuery *query = [[self descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
  NSArray *childElements = [query allElementsBoundByIndex];
  return childElements;
}


#pragma mark - Search by xpath

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXPathQuery:(NSString *)xpathQuery
{
  // XPath will try to match elements only class name, so requesting elements by XCUIElementTypeAny will not work. We should use '*' instead.
  xpathQuery = [xpathQuery stringByReplacingOccurrencesOfString:@"XCUIElementTypeAny" withString:@"*"];
  NSArray *matchingSnapshots = [self.lastSnapshot fb_descendantsMatchingXPathQuery:xpathQuery];
  NSArray *allElements = [[self descendantsMatchingType:XCUIElementTypeAny] allElementsBoundByIndex];
  NSArray *matchingElements = [self filterElements:allElements matchingSnapshots:matchingSnapshots];
  return matchingElements;
}

- (NSArray<XCUIElement *> *)filterElements:(NSArray<XCUIElement *> *)elements matchingSnapshots:(NSArray<XCElementSnapshot *> *)snapshots
{
  NSMutableArray *matchingElements = [NSMutableArray array];
  [snapshots enumerateObjectsUsingBlock:^(XCElementSnapshot *snapshot, NSUInteger snapshotIdx, BOOL *stopSnapshotEnum) {
    [elements enumerateObjectsUsingBlock:^(XCUIElement *element, NSUInteger elementIdx, BOOL *stopElementEnum) {
      [element resolve];
      if ([element.lastSnapshot _matchesElement:snapshot]) {
        [matchingElements addObject:element];
        *stopElementEnum = YES;
      }
    }];
  }];
  return matchingElements.copy;
}


#pragma mark - Search by Accessibility Id

- (NSArray<XCUIElement *> *)fb_descendantsMatchingIdentifier:(NSString *)accessibilityId
{
  NSMutableArray *result = [NSMutableArray array];
  if (self.identifier == accessibilityId) {
    [result addObject:self];
  }
  NSArray *children = [[[self descendantsMatchingType:XCUIElementTypeAny] matchingIdentifier:accessibilityId] allElementsBoundByIndex];
  [result addObjectsFromArray: children];
  return result.copy;
}

#pragma mark - Search by Xui

- (NSArray<XCUIElement *> *)av_descendantsMatchingXui:(NSString *)locator
{
  // Делим локатор по вертикальной черте на элементы.
  NSMutableArray *resultElementList = [NSMutableArray array];
  NSArray *tokens = [self av_parseLocator:locator];
  NSError *error = nil;
  // Создаем регулярку для парсинга одной части локатора.
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\.{0,1})([0-9\\*]*)(\\(.+\\))*(\\[[0-9a-z]+\\]){0,1}$" options:NSRegularExpressionCaseInsensitive error:&error];

  __block XCUIElement *currentElement = self;

  // Цикл обходит все элементы локатора.
  [tokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger tokenIdx, BOOL *stopTokenEnum) {
      NSTextCheckingResult *regRes = [self av_parsePartOfLocator:regex locator:token];
      XCUIElementQuery *query = [self av_getQueryByType:regRes locator:token element:currentElement];
      currentElement = [self av_getElement:regRes locator:token query:query];

  }];

  [resultElementList addObject:currentElement];
  return resultElementList.copy;
}

- (NSArray *)av_parseLocator:(NSString *)locator {
  return  [locator componentsSeparatedByString:@"|"];
}

- (NSTextCheckingResult *)av_parsePartOfLocator:(NSRegularExpression *)regex locator: (NSString *)locator {
  NSArray *matches = [regex matchesInString:locator
                                    options:NSMatchingAnchored
                                      range:NSMakeRange(0, [locator length])];
  if ([matches count] == 0) {
    NSString *message = [NSString stringWithFormat: @"Bad part of locator: %@", locator];
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:message userInfo:nil];
  }
  return [matches objectAtIndex:0];
}

-(XCUIElementQuery *)av_getQueryByType:(NSTextCheckingResult *)regRes locator: (NSString *)locator element: (XCUIElement *)element {
  // Получаем признак того нужен ли нам потомок или ребенок.
  NSRange childCharRange = [regRes rangeAtIndex:1];
  NSString *childChar = [locator substringWithRange:childCharRange];
  // Получаем тип запрашеваемого элемента.
  NSRange typeRange = [regRes rangeAtIndex:2];
  NSString *type = [locator substringWithRange:typeRange];
  NSInteger elementType ;
  XCUIElementQuery *query;

  // Если тип указан как звездочка, значит берем любой элемент, если указан пробрасываем его.
  if ([type isEqualToString:@"*"]) {
    elementType = XCUIElementTypeAny;
  } else {
    elementType = [type intValue];
  }

  // Если в начале стоит точка, то мы берем ребенка, если нет, то потомка.
  if ([childChar isEqualToString:@"."]) {
    query = [element childrenMatchingType:elementType];
  } else {
    query = [element descendantsMatchingType:elementType];
  }
  return query;
}

- (XCUIElement *)av_getElement:(NSTextCheckingResult *)regRes
                       locator:(NSString *)locator
                       query:(XCUIElementQuery *)query
{
  // Инициализируем переменные для условия.
  Boolean hasPredicate = false;
  NSString *predicate;

  // Инициализируем переменные для индекса.
  Boolean hasIndex = false;
  NSString *index;

  // Получае количество совпандений в строки по регулярному вырожению.
  NSInteger countMatches = [regRes numberOfRanges];

  // В цикле перебераем оставшиеся части локатора элемента.
  for (NSInteger i = 3; i < countMatches; i++) {
    NSRange optionRange = [regRes rangeAtIndex:i];
    // Если совпадение присутствует в массиве, но пустое, то идем дальше
    if (optionRange.length == 0) {
      continue;
    }
    // Получем строку совпадения.
    NSString *option = [locator substringWithRange:optionRange];

    // Проверяем является ли часть локатора элемента условием с помощью regex, если является сохраняем информацию
    // в перменные и переходим к следующей итерации.
    NSError *errorCond = nil;
    NSRegularExpression *regexCondition = [NSRegularExpression regularExpressionWithPattern:@"\\((.*)\\)" options:NSRegularExpressionCaseInsensitive error:&errorCond];
    NSArray *predicateMatches = [regexCondition matchesInString:option
                                                        options:NSMatchingAnchored
                                                          range:NSMakeRange(0, [option length])];
    if ([predicateMatches count] > 0) {
      NSTextCheckingResult *regConditionRes = [predicateMatches objectAtIndex:0];
      NSInteger condCount = [regConditionRes numberOfRanges];
      if (condCount > 0) {
        hasPredicate = true;
        NSRange predicateRange = [regConditionRes rangeAtIndex:1];
        predicate = [option substringWithRange:predicateRange];
        continue;
      }
    }

    // Проверяем является ли часть локатора элемента индексом с помощью regex, если является сохраняем информацию
    // в перменные.
    NSError *errorInd = nil;
    NSRegularExpression *regexIndex = [NSRegularExpression regularExpressionWithPattern:@"\\[(.*)\\]" options:NSRegularExpressionCaseInsensitive error:&errorInd];
    NSArray *indexMatches = [regexIndex matchesInString:option
                                                options:NSMatchingAnchored
                                                  range:NSMakeRange(0, [option length])];
    if ([indexMatches count] > 0) {
      NSTextCheckingResult *regIndexRes = [indexMatches objectAtIndex:0];
      NSInteger indexCount = [regIndexRes numberOfRanges];
      if (indexCount > 0) {
        hasIndex = true;
        NSRange indexRange = [regIndexRes rangeAtIndex:1];
        index = [option substringWithRange:indexRange];
      }
    }
  }

  // Применение условий к запросу элемента
  if (hasPredicate) {
    if ([predicate hasPrefix:@"id"]) {
      NSArray *explodeResult = [predicate componentsSeparatedByString:@"="];
      query = [query matchingIdentifier:explodeResult[1]];
    } else {
      NSPredicate *predicateObj = [NSPredicate predicateWithFormat:predicate];
      query = [query matchingPredicate:predicateObj];
    }
  }

  // Применяем индекс к запросу или к массиву. Если индекс не указан, то берем первый элемент.
  XCUIElement *element;
  if (hasIndex) {
    if ([index isEqualToString:@"last"]) {
      element = [[query allElementsBoundByIndex] lastObject];
    } else {
      element = [query elementBoundByIndex:[index intValue]];
    }
  } else {
    element = [query elementBoundByIndex:0];
  }
  return element;
}

@end
