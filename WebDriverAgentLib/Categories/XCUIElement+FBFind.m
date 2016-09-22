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

#pragma mark - Search by CellByIndex

- (NSArray<XCUIElement *> *)fb_descendantsMatchingXui:(NSString *)locator
{
  // Делим локатор по вертикальной черте на элементы.
  NSMutableArray *resultElementList = [NSMutableArray array];
  NSArray *tokens = [locator componentsSeparatedByString:@"|"];
  NSError *error = nil;
  // Создаем регулярку для парсинга одной части локатора.
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\.{0,1})([0-9\\*]*)(\\(.+\\))*(\\[[0-9a-z]+\\]){0,1}$" options:NSRegularExpressionCaseInsensitive error:&error];

  __block XCUIElement *currentElement = self;

  // Цикл обходит все элементы локатора.
  [tokens enumerateObjectsUsingBlock:^(NSString *token, NSUInteger tokenIdx, BOOL *stopTokenEnum) {
      // Проверяем по регекспу созданному ранее, что локатор элемента корректный и парсим его.
      NSArray *matches = [regex matchesInString:token
                                        options:NSMatchingAnchored
                                          range:NSMakeRange(0, [token length])];
      NSTextCheckingResult *regRes = [matches objectAtIndex:0];
      // Получае количество совпандений в строки по регулярному вырожению.
      NSInteger count = [regRes numberOfRanges];
      // Получаем признак того нужен ли нам потомок или ребенок.
      NSRange childCharRange = [regRes rangeAtIndex:1];
      NSString *childChar = [token substringWithRange:childCharRange];
      // Получаем тип запрашеваемого элемента.
      NSRange typeRange = [regRes rangeAtIndex:2];
      NSString *type = [token substringWithRange:typeRange];
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
        query = [currentElement childrenMatchingType:elementType];
      } else {
        query = [currentElement descendantsMatchingType:elementType];
      }

      // Инициализируем переменные для условия.
      Boolean hasCondition = false;
      NSRange condTypeRange;
      NSRange valueRange;
      NSString *condType;
      NSString *value;

      // Инициализируем переменные для индекса.
      Boolean hasIndex = false;
      NSRange indexRange;
      NSString *index;

      // В цикле перебераем оставшиеся части локатора элемента.
      for (NSInteger i = 3; i < count; i++) {
        NSRange optionRange = [regRes rangeAtIndex:i];
        // Если совпадение присутствует в массиве, но пустое, то идем дальше
        if (optionRange.length == 0) {
          continue;
        }
        // Получем строку совпадения.
        NSString *option = [token substringWithRange:optionRange];

        // Проверяем является ли часть локатора элемента условием с помощью regex, если является сохраняем информацию
        // в перменные и переходим к следующей итерации.
        NSError *errorCond = nil;
        NSRegularExpression *regexCondition = [NSRegularExpression regularExpressionWithPattern:@"\\((.*)=(.*)\\)" options:NSRegularExpressionCaseInsensitive error:&errorCond];
        NSArray *conditionMatches = [regexCondition matchesInString:option
                                          options:NSMatchingAnchored
                                            range:NSMakeRange(0, [option length])];
        if ([conditionMatches count] > 0) {
          NSTextCheckingResult *regConditionRes = [conditionMatches objectAtIndex:0];
          NSInteger condCount = [regConditionRes numberOfRanges];
          if (condCount > 0) {
            hasCondition = true;
            condTypeRange = [regConditionRes rangeAtIndex:1];
            valueRange = [regConditionRes rangeAtIndex:2];
            condType = [option substringWithRange:condTypeRange];
            value = [option substringWithRange:valueRange];
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
            indexRange = [regIndexRes rangeAtIndex:1];
            index = [option substringWithRange:indexRange];
          }
        }
      }

      // Признак того будет ли результат применени я условий запросом или массивом.
      Boolean isArray = false;
      NSArray *array;

      // TODO: Переписать что бы всегда работать с запросом.
      // Применение условий к запросу элемента
      if (hasCondition) {
        if ([condType isEqualToString:@"id"]) {
          query = [query matchingIdentifier:value];
        } else {
          array = [currentElement fb_descendantsMatchingProperty:condType value:value partialSearch:false];
          if ([array count] == 0) {
            query = [currentElement childrenMatchingType:XCUIElementTypeOther];
          } else {
            isArray = true;
          }
        }
      }

      // Применяем индекс к запросу или к массиву. Если индекс не указан, то берем первый элемент.
      if (hasIndex) {
        if (isArray) {
          if ([index isEqualToString:@"last"]) {
            currentElement = [array lastObject];
          } else {
            currentElement = array[[index intValue]];
          }
        } else {
          if ([index isEqualToString:@"last"]) {
            currentElement = [[query allElementsBoundByIndex] lastObject];
          } else {
            currentElement = [query elementBoundByIndex:[index intValue]];
          }
        }
      } else {
        if (isArray) {
          currentElement = array[0];
        } else {
          currentElement = [query elementBoundByIndex:0];
        }
      }
  }];
  
  [resultElementList addObject:currentElement];
  return resultElementList.copy;
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

@end
