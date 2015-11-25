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
#import "UIAElement+WebDriverAttributes.h"
#import "UIATarget.h"
#import "UIAXElement.h"

static NSDictionary *InfoForElement(UIAElement *element, BOOL verbose);

@implementation FBDebugCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/tree"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return [self handleTreeCommandWithParams:request];
    }],
    [[FBRoute GET:@"/session/:sessionID/tree"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return [self handleTreeCommandWithParams:request];
    }],
    [[FBRoute GET:@"/session/:sessionID/source"] respond: ^ id<FBResponsePayload> (FBRouteRequest *request) {
      return [self handleTreeCommandWithParams:request];
    }],
  ];
}

#pragma mark - Helpers

+ (id<FBResponsePayload>)handleTreeCommandWithParams:(FBRouteRequest *)params
{
  BOOL verbose = [params.parameters[@"verbose"] boolValue];
  NSDictionary *info = [self.class JSONTreeForTargetWithVerbose:verbose];
  return FBResponseDictionaryWithStatus(FBCommandStatusNoError, @{ @"tree": info });
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

static NSDictionary *InfoForElement(UIAElement *element, BOOL verbose)
{
  NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

  info[@"type"] = NSStringFromClass([element class]);
  info[@"name"] = ValueOrNull([element wdName]);
  info[@"value"] = ValueOrNull([element wdValue]);
  info[@"label"] = ValueOrNull([element wdLabel]);

  if ([element isEnabled]) {
    info[@"isEnabled"] = [@([element isWDEnabled]) stringValue];
  }
  if ([element isVisible]) {
    info[@"isVisible"] = [@([element isWDVisible]) stringValue];
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
  info[@"rect"] = [element wdRect];

  return info;
}
