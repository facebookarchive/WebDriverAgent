/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBErrorBuilder.h"

static NSString *const FBWebServerErrorDomain = @"com.facebook.WebDriverAgent";

@interface FBErrorBuilder ()
@property (nonatomic, copy) NSString *errorDescription;
@property (nonatomic, strong) NSError *innerError;
@end

@implementation FBErrorBuilder

+ (instancetype)builder
{
  return [FBErrorBuilder new];
}

- (instancetype)withDescription:(NSString *)description
{
  self.errorDescription = description;
  return self;
}

- (instancetype)withDescriptionFormat:(NSString *)format, ...
{
  va_list argList;
  va_start(argList, format);
  self.errorDescription = [[NSString alloc] initWithFormat:format arguments:argList];
  va_end(argList);
  return self;
}

- (instancetype)withInnerError:(NSError *)error
{
  self.innerError = error;
  return self;
}

- (BOOL)buildError:(NSError **)errorOut
{
  if (errorOut) {
    *errorOut = [self build];
  }
  return NO;
}

- (NSError *)build
{
  return
  [NSError errorWithDomain:FBWebServerErrorDomain
                      code:1
                  userInfo:[self buildUserInfo]
   ];
}

- (NSDictionary *)buildUserInfo
{
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  if (self.errorDescription) {
    userInfo[NSLocalizedDescriptionKey] = self.errorDescription;
  }
  if (self.innerError) {
    userInfo[NSUnderlyingErrorKey] = self.innerError;
  }
  return userInfo.copy;
}

@end
