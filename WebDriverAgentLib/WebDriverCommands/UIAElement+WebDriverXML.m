/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIAElement+WebDriverXML.h"

#import "FBWDAMacros.h"

static NSString *const kXMLIndexPathKey = @"private_indexPath";

@implementation UIAElement (WebDriverXML)

- (DDXMLElement *)webDriverXMLElement:(NSMutableDictionary *)elementStore
{
  FBWDAAssertMainThread();

  [[self class] pushPatience:0];
  DDXMLElement *element = [self _webDriverXMLElement:@"" elementStore:elementStore];
  [[self class] popPatience];

  return element;
}

- (DDXMLElement *)_webDriverXMLElement:(NSString *)indexPath elementStore:(NSMutableDictionary *)elementStore
{
  DDXMLElement *element = [[DDXMLElement alloc] initWithName:NSStringFromClass([self class])];

  [element addAttribute:[DDXMLNode attributeWithName:@"type" stringValue:NSStringFromClass([self class])]];
  if ([self value]) {
    id value = [self value];
    NSString *stringValue;
    if ([value isKindOfClass:[NSValue class]]) {
      stringValue = [value stringValue];
    } else if ([value isKindOfClass:[NSString class]]) {
      stringValue = value;
    } else {
      stringValue = [value description];
    }
    [element addAttribute:[DDXMLNode attributeWithName:@"value" stringValue:stringValue]];
  }
  if ([self name]) {
    [element addAttribute:[DDXMLNode attributeWithName:@"name" stringValue:[self name]]];
  }
  if ([self label]) {
    [element addAttribute:[DDXMLNode attributeWithName:@"label" stringValue:[self label]]];
  }
  [element addAttribute:[DDXMLNode attributeWithName:kXMLIndexPathKey stringValue:indexPath]];

  NSArray *children = [self elements];
  for (NSUInteger i  = 0; i < [children count]; i++) {
    UIAElement *childElement = children[i];
    NSString *newIndexPath = [indexPath stringByAppendingFormat:@",%lu", (unsigned long)i];
    elementStore[newIndexPath] = childElement;
    [element addChild:[childElement _webDriverXMLElement:newIndexPath elementStore:elementStore]];
  }

  return element;
}

- (NSArray *)childrenFromXpathQuery:(NSString *)xpathQuery
{
  NSMutableDictionary *elementStore = [NSMutableDictionary dictionary];
  DDXMLElement *xmlElement = [self webDriverXMLElement:elementStore];
  NSError *error;
  NSArray *xpathNodes = [xmlElement nodesForXPath:xpathQuery error:&error];
  if (![xpathNodes count]) {
    return nil;
  }

  NSMutableArray *elements = [NSMutableArray arrayWithCapacity:[xpathNodes count]];
  for (DDXMLElement *childXMLElement in xpathNodes) {
    [elements addObject:[elementStore objectForKey:[[childXMLElement attributeForName:kXMLIndexPathKey] stringValue]]];
  }
  return elements;
}

@end
