/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBInspectorCommands.h"

@implementation FBInspectorCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/inspector"].withoutSession respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseFileWithPath([[self class] inspectorHTMLFilePath]);
    }],
    [[FBRoute GET:@"/inspector.js"].withoutSession respondWithBlock: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return FBResponseFileWithPath([[self class] inspectorJSFilePath]);
    }],
  ];
}

+ (NSBundle *)inspectorResourcesBundle
{
    static dispatch_once_t onceToken;
    static NSBundle *inspectorResourcesBundle;
    dispatch_once(&onceToken, ^{
      NSURL *url = [[NSBundle bundleForClass:[self class]]
                    URLForResource:@"WebDriverAgent" withExtension:@"bundle"];
      inspectorResourcesBundle = [NSBundle bundleWithURL:url];
    });
    return inspectorResourcesBundle;
}

+ (NSString *)inspectorHTMLFilePath
{
    return [[self inspectorResourcesBundle] pathForResource:@"index" ofType:@"html"];
}

+ (NSString *)inspectorJSFilePath
{
    return [[self inspectorResourcesBundle] pathForResource:@"inspector" ofType:@"js"];
}

@end
