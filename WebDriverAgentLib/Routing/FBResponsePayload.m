/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponsePayload.h"

#import "FBElementCache.h"
#import "FBResponseFilePayload.h"
#import "FBResponseJSONPayload.h"
#import "FBSession.h"
#import "FBMathUtils.h"
#import "FBConfiguration.h"
#import "FBMacros.h"

#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"

NSString *arbitraryAttrPrefix = @"attribute/";

id<FBResponsePayload> FBResponseWithOK()
{
  return FBResponseWithStatus(FBCommandStatusNoError, nil);
}

id<FBResponsePayload> FBResponseWithObject(id object)
{
  return FBResponseWithStatus(FBCommandStatusNoError, object);
}

id<FBResponsePayload> FBResponseWithCachedElement(XCUIElement *element, FBElementCache *elementCache, BOOL compact)
{
  NSString *elementUUID = [elementCache storeElement:element];
  return FBResponseWithStatus(FBCommandStatusNoError, FBDictionaryResponseWithElement(element, elementUUID, compact));
}

id<FBResponsePayload> FBResponseWithCachedElements(NSArray<XCUIElement *> *elements, FBElementCache *elementCache, BOOL compact)
{
  NSMutableArray *elementsResponse = [NSMutableArray array];
  for (XCUIElement *element in elements) {
    NSString *elementUUID = [elementCache storeElement:element];
    [elementsResponse addObject:FBDictionaryResponseWithElement(element, elementUUID, compact)];
  }
  return FBResponseWithStatus(FBCommandStatusNoError, elementsResponse);
}

id<FBResponsePayload> FBResponseWithElementUUID(NSString *elementUUID)
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:@{
    @"id" : elementUUID,
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"value" : @"",
    @"status" : @0,
  }];
}

id<FBResponsePayload> FBResponseWithError(NSError *error)
{
  return FBResponseWithStatus(FBCommandStatusUnhandled, error.description);
}

id<FBResponsePayload> FBResponseWithErrorFormat(NSString *format, ...)
{
  va_list argList;
  va_start(argList, format);
  NSString *errorMessage = [[NSString alloc] initWithFormat:format arguments:argList];
  id<FBResponsePayload> payload = FBResponseWithStatus(FBCommandStatusUnhandled, errorMessage);
  va_end(argList);
  return payload;
}

id<FBResponsePayload> FBResponseWithStatus(FBCommandStatus status, id object)
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:@{
    @"value" : object ?: @{},
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"status" : @(status),
  }];
}

id<FBResponsePayload> FBResponseFileWithPath(NSString *path)
{
  return [[FBResponseFilePayload alloc] initWithFilePath:path];
}

inline NSDictionary *FBDictionaryResponseWithElement(XCUIElement *element, NSString *elementUUID, BOOL compact)
{
  NSMutableDictionary *dictionary = [NSMutableDictionary new];
  dictionary[@"ELEMENT"] = elementUUID;
  if (!compact) {
    NSArray *fields = [FBConfiguration.elementResponseAttributes componentsSeparatedByString:@","];
    XCElementSnapshot *snapshot = element.fb_lastSnapshotFromQuery;
    for(NSString *field in fields) {
      // 'name' here is the w3c-approved identifier for what we mean by 'type'
      if ([field isEqualToString:@"name"] || [field isEqualToString:@"type"]) {
        dictionary[field] = snapshot.wdType;
      } else if ([field isEqualToString:@"text"]) {
        dictionary[field] = FBFirstNonEmptyValue(snapshot.wdValue, snapshot.wdLabel) ?: [NSNull null];
      } else if ([field isEqualToString:@"rect"]) {
        dictionary[field] = FBwdRectNoInf(snapshot.wdRect);
      } else if ([field isEqualToString:@"enabled"]) {
        dictionary[field] = @(snapshot.wdEnabled);
      } else if ([field isEqualToString:@"displayed"]) {
        dictionary[field] = @(snapshot.wdVisible);
      } else if ([field isEqualToString:@"selected"]) {
        dictionary[field] = @(snapshot.selected);
      } else if ([field isEqualToString:@"label"]) {
        dictionary[field] = snapshot.wdLabel ?: [NSNull null];;
      } else if ([field hasPrefix:arbitraryAttrPrefix]) {
        NSString *attributeName = [field substringFromIndex:[arbitraryAttrPrefix length]];
        dictionary[field] = [snapshot fb_valueForWDAttributeName:attributeName] ?: [NSNull null];
      }
    }
  }
  return dictionary.copy;
}
