/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponsePayload.h"

#import "FBSessionCommands.h"

#import "FBResponseFilePayload.h"
#import "FBResponseJSONPayload.h"

id<FBResponsePayload> FBResponseDictionaryWithElementID(NSUInteger elementID)
{
  return [FBResponsePayload withElementID:elementID];
}

id<FBResponsePayload> FBResponseDictionaryWithStatus(FBCommandStatus status, id object)
{
  return [FBResponsePayload withStatus:status object:object];
}

id<FBResponsePayload> FBResponseDictionaryWithOK(void)
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
    @"sessionId" : FBSessionCommands.sessionId ?: NSNull.null,
    @"value" : @"",
    @"status" : @0,
  }];
}

+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status
{
  return [self withStatus:status object:nil];
}

+ (id<FBResponsePayload>)withStatus:(FBCommandStatus)status object:(id)object
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:@{
    @"value" : object ?: @{},
    @"sessionId" : FBSessionCommands.sessionId ?: NSNull.null,
    @"status" : @(status),
  }];
}

+ (id<FBResponsePayload>)withFileAtPath:(NSString *)path
{
  return [[FBResponseFilePayload alloc] initWithFilePath:path];
}

@end
