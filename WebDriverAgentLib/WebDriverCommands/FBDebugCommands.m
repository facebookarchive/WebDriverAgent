/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBDebugCommands.h"

#import <UIKit/UIKit.h>

#import "FBRouteRequest.h"
#import "UIAApplication.h"
#import "UIAElement.h"
#import "UIATarget.h"
#import "UIAXElement.h"

NSDictionary *InfoForElement(UIAElement *element, BOOL verbose);

@implementation FBDebugCommands

#pragma mark - <FBCommandHandler>

+ (NSDictionary *)routeHandlers
{
  return
  @{
    @"GET@/tree" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [self handleTreeCommandWithParams:request completionHandler:completionHandler];
    },
    @"GET@/session/:sessionID/tree" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [self handleTreeCommandWithParams:request completionHandler:completionHandler];
    },
    @"GET@/session/:sessionID/source" : ^(FBRouteRequest *request, FBRouteResponseCompletion completionHandler) {
      [self handleTreeCommandWithParams:request completionHandler:completionHandler];
    },
  };
}

#pragma mark - Helpers

+ (void)handleTreeCommandWithParams:(FBRouteRequest *)params completionHandler:(FBRouteResponseCompletion)completionHandler
{
  BOOL verbose = [params.parameters[@"verbose"] boolValue];
  NSDictionary *info = [self.class JSONTreeForTargetWithVerbose:verbose];
  completionHandler(FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{ @"tree": info }));
}

+ (NSDictionary *)JSONTreeForTargetWithVerbose:(BOOL)verbose
{
  [UIAElement pushPatience:0];
  NSDictionary *info = InfoForElement([[UIATarget localTarget] frontMostApp], verbose);
  [UIAElement popPatience];

  return info;
}

@end

static id ValueOrNull(id value) {
  return value ?: [NSNull null];
}

NSDictionary *InfoForElement(UIAElement *element, BOOL verbose)
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

  info[@"type"] = NSStringFromClass([element class]);
  info[@"name"] = ValueOrNull([element name]);
  info[@"value"] = ValueOrNull([element value]);
  info[@"label"] = ValueOrNull([element label]);

  if ([element isEnabled]) {
    info[@"isEnabled"] = [[element isEnabled] stringValue];
  }
  if ([element isVisible]) {
    info[@"isVisible"] = [[element isVisible] stringValue];
  }
  if ([element attributes]) {
    NSDictionary *attributes = [element attributes];
    info[@"attributes"] = [NSDictionary dictionaryWithObjects:[[attributes allValues] valueForKey:@"description"] forKeys:[attributes allKeys]];
  }

  if (verbose) {
    if ([element uiaxElement]) {
      info[@"uiaxAttributes"] = [[[element uiaxElement] valuesForAllKnownAttributes] description];
    }
  }

  NSArray *childElements = [element elements];
  if ([childElements count]) {
    info[@"children"] = [[NSMutableArray alloc] init];
    for (UIAElement *childElement in childElements) {
      [info[@"children"] addObject:InfoForElement(childElement, verbose)];
    }
  }
  info[@"rect"] = NSStringFromCGRect([[element rect] CGRectValue]);

  return info;
}
