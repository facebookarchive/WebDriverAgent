/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBCommandHandler.h"

#import "FBResponseFilePayload.h"
#import "FBResponseJSONPayload.h"

id<FBResponsePayload> FBResponseDictionaryWithElementID(NSUInteger elementID)
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:
      @{
        @"id" : @(elementID),
        @"value" : @"",
        @"status" : @0,
      }];
}

id<FBResponsePayload> FBResponseDictionaryWithStatus(FBCommandStatus status, id object)
{
  return [[FBResponseJSONPayload alloc] initWithDictionary:
      @{
        @"value" : object,
        @"status" : @(status),
      }];
}

id<FBResponsePayload> FBResponseDictionaryWithOK(void)
{
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @"");
}

id<FBResponsePayload> FBResponseFileWithPath(NSString *path)
{
    return [[FBResponseFilePayload alloc] initWithFilePath:path];
}
