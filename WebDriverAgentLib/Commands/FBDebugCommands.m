/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBDebugCommands.h"

#import "FBApplication.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "XCUIApplication+FBHelpers.h"
#import "FBXPath.h"

@implementation FBDebugCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/source/:type"] respondWithTarget:self action:@selector(handleGetSourceCommand:)],
    [[FBRoute GET:@"/source/:type"].withoutSession respondWithTarget:self action:@selector(handleGetSourceCommand:)],
    // TODO: Kill source methods, that support json representation only
    [[FBRoute GET:@"/source"] respondWithTarget:self action:@selector(handleGetTreeCommand:)],
    [[FBRoute GET:@"/source"].withoutSession respondWithTarget:self action:@selector(handleGetTreeCommand:)],
    // TODO: Kill POST methods for source and move accessiblity tree to extension scheme
    [[FBRoute POST:@"/source"] respondWithTarget:self action:@selector(handleGetTreeCommand:)],
    [[FBRoute POST:@"/source"].withoutSession respondWithTarget:self action:@selector(handleGetTreeCommand:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetTreeCommand:(FBRouteRequest *)request
{
  FBApplication *application = request.session.application ?: [FBApplication fb_activeApplication];
  if (!application) {
    return FBResponseWithErrorFormat(@"There is no active application");
  }
  const BOOL accessibleTreeType = [request.arguments[@"accessible"] boolValue];
  return FBResponseWithStatus(FBCommandStatusNoError, @{ @"tree": (accessibleTreeType ? application.fb_accessibilityTree : application.fb_tree) ?: @{} } );
}

+ (id<FBResponsePayload>)handleGetSourceCommand:(FBRouteRequest *)request
{
  FBApplication *application = request.session.application ?: [FBApplication fb_activeApplication];
  NSString *sourceType = request.parameters[@"type"];
  id result;
  if ([sourceType caseInsensitiveCompare:@"json"] == NSOrderedSame) {
    result = application.fb_tree;
  } else if ([sourceType caseInsensitiveCompare:@"xml"] == NSOrderedSame) {
    result = [FBXPath xmlStringWithSnapshot:application.lastSnapshot];
  } else {
    return FBResponseWithStatus(FBCommandStatusUnsupported, [NSString stringWithFormat:@"Unknown source type '%@'. Only 'xml' and 'json' source types are supported.", sourceType]);
  }
  if (nil == result) {
    return FBResponseWithStatus(FBCommandStatusUnhandled, [NSString stringWithFormat:@"Cannot get '%@' source of the current application", sourceType]);
  }
  return FBResponseWithStatus(FBCommandStatusNoError, @{ @"tree": result });
}

@end
