/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBResponse.h"

#import <RoutingHTTPServer/RouteResponse.h>

#import "FBSessionCommands.h"
#import "FBWDAConstants.h"
#import "FBWDALogger.h"

@interface FBResponse_File : NSObject <FBResponse>

@property (nonatomic, copy, readwrite) NSString *path;

@end

@implementation FBResponse_File

- (void)dispatchWithResponse:(RouteResponse *)response
{
  [FBWDALogger verboseLogFmt:@"Respond with file %@", self.path];
  [response respondWithFile:self.path];
}

- (BOOL)isSuccessfulStatus
{
  return YES;
}

@end

@interface FBResponse_JSON : NSObject <FBResponse>

@property (nonatomic, copy, readwrite) NSDictionary *dictionary;

@end

@implementation FBResponse_JSON

- (void)dispatchWithResponse:(RouteResponse *)response
{
  NSError *error;
  NSData *jsonData = [NSJSONSerialization
    dataWithJSONObject:self.dictionary
    options:NSJSONWritingPrettyPrinted
    error:&error];

  if (FBWDAConstants.verboseLoggingEnabled) {
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [FBWDALogger verboseLogFmt:@"Respond with json %@", jsonString];
  }

  NSCAssert(jsonData, @"Valid JSON must be responded, error of %@", error);
  [response respondWithData:jsonData];
}

- (BOOL)isSuccessfulStatus
{
  return self.dictionary[@"status"] && [self.dictionary[@"status"] unsignedIntegerValue] == FBCommandStatusNoError;
}

@end

@implementation FBResponse

+ (id<FBResponse>)ok
{
  return [self withStatus:FBCommandStatusNoError object:nil];
}

+ (id<FBResponse>)okWith:(id)object
{
  return [self withStatus:FBCommandStatusNoError object:object];
}

+ (id<FBResponse>)withElementID:(NSUInteger)elementID
{
  FBResponse_JSON *response = [FBResponse_JSON new];
  response.dictionary = @{
    @"id" : @(elementID),
    @"sessionId" : FBSessionCommands.sessionId ?: NSNull.null,
    @"value" : @"",
    @"status" : @(FBCommandStatusNoError)
  };
  return response;
}

+ (id<FBResponse>)withStatus:(FBCommandStatus)status
{
  return [self withStatus:status object:nil];
}

+ (id<FBResponse>)withStatus:(FBCommandStatus)status object:(id)object
{
  FBResponse_JSON *response = [FBResponse_JSON new];
  response.dictionary = @{
    @"value" : object ?: @{},
    @"sessionId" : FBSessionCommands.sessionId ?: NSNull.null,
    @"status" : @(status)
  };
  return response;
}

+ (id<FBResponse>)withFileAtPath:(NSString *)path
{
  FBResponse_File *response = [FBResponse_File new];
  response.path = path;
  return response;
}

@end
