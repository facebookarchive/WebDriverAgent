/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import "XCUIElement+AVFind.h"

#import "XCUIElement+FBWebDriverAttributes.h"

@implementation XCUIElement (FBFind)

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
  __block NSArray<XCUIElement *> *currentElements;

  // Цикл обходит все элементы локатора.
  [tokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger tokenIdx, BOOL *stopTokenEnum) {
      NSTextCheckingResult *regRes = [self av_parsePartOfLocator:regex locator:token];
      XCUIElementQuery *query = [self av_getQueryByType:regRes locator:token element:currentElement];
      currentElements = [self av_getElements:regRes locator:token query:query];
      if ([currentElements count] > 0) {
          currentElement = [currentElements objectAtIndex:0];
      }
  }];

//  [resultElementList addObject:currentElement];
  resultElementList = [NSMutableArray arrayWithArray:currentElements];
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

- (NSArray<XCUIElement *> *)av_getElements:(NSTextCheckingResult *)regRes
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
  NSArray<XCUIElement *> *resElements;
  NSArray<XCUIElement *> *elements = [query allElementsBoundByIndex];
  if (hasIndex) {
    if ([index isEqualToString:@"last"]) {
      element = [elements lastObject];
      resElements = [NSArray arrayWithObject:element];
    } else {
        if ([elements count] > (NSUInteger) [index integerValue]) {
            element = [elements objectAtIndex:[index intValue]];
            resElements = [NSArray arrayWithObject:element];
        }
    }
  } else {
      resElements = elements;
  }
  return resElements;
}

@end
