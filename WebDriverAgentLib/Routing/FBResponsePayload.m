/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponsePayload.h"

#import "FBSession.h"

#import "FBResponseFilePayload.h"
#import "FBResponseJSONPayload.h"

id<FBResponsePayload> FBResponseWithElementID(NSUInteger elementID)
{
  return [FBResponsePayload withElementID:elementID];
}

id<FBResponsePayload> FBResponseWithError(NSError *error)
{
  return [FBResponsePayload withError:error];
}

id<FBResponsePayload> FBResponseWithErrorFormat(NSString *format, ...)
{
  va_list argList;
  va_start(argList, format);
  id<FBResponsePayload> payload = [FBResponsePayload withErrorFormat:format arguments:argList];
  va_end(argList);
  return payload;
}

id<FBResponsePayload> FBResponseWithStatus(FBCommandStatus status, id object)
{
  return [FBResponsePayload withStatus:status object:object];
}

id<FBResponsePayload> FBResponseWithOK(void)
{
  return FBResponsePayload.ok;
}

id<FBResponsePayload> FBResponseFileWithPath(NSString *path)
{
  return [FBResponsePayload withFileAtPath:path];
}

@implementation FBResponsePayload

+ (id<FBResponsePayload>)ok
{
  return [self withStatus:FBCommandStatusNoError object:nil];
}

+ (id<FBResponsePayload>)okWith:(id)object
{
  return [self withStatus:FBCommandStatusNoError object:object];
}

+ (id<FBResponsePayload>)withElementID:(NSUInteger)elementID
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:@{
    @"id" : @(elementID),
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"value" : @"",
    @"status" : @0,
  }];
}

+ (id<FBResponsePayload>)withError:(NSError *)error
{
  return [self withStatus:FBCommandStatusUnhandled object:error.description];
}

+ (id<FBResponsePayload>)withErrorFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
  va_list argList;
  va_start(argList, format);
  id<FBResponsePayload> payload = [self withErrorFormat:format arguments:argList];
  NSLogv(format, argList);
  va_end(argList);
  return payload;
}

+ (id<FBResponsePayload>)withErrorFormat:(NSString *)format arguments:(va_list)argList NS_FORMAT_FUNCTION(1,0)
{
  NSString *errorMessage = [[NSString alloc] initWithFormat:format arguments:argList];
  return [self withStatus:FBCommandStatusUnhandled object:errorMessage];
}

+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status
{
  return [self withStatus:status object:nil];
}

+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status object:(id)object
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:@{
    @"value" : object ?: @{},
    @"sessionId" : [FBSession activeSession].identifier ?: NSNull.null,
    @"status" : @(status),
  }];
}

+ (id<FBResponsePayload>)withFileAtPath:(NSString *)path
{
  return [[FBResponseFilePayload alloc] initWithFilePath:path];
}

@end
