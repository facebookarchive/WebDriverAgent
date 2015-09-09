/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBWebDriverViewHierarchyMock.h"

#import <OCMock/OCMock.h>

#import "UIAApplication.h"
#import "UIAElement+ChildHelpers.h"
#import "UIAElement+WebDriverXML.h"
#import "UIAElement.h"
#import "UIATarget.h"

@interface FBWebDriverViewHierarchyMock ()
@property (nonatomic, strong) id mockTarget;
@property (nonatomic, strong) id mockApplication;
@end

@implementation UIAElement (TestIdentifier)

- (NSString *)identifier { return nil; }

@end

@implementation FBWebDriverViewHierarchyMock

+ (instancetype)sharedInstance
{
  static id instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (void)mockAppWithWindowDefinitions:(NSArray *)definitons
{
  NSMutableArray *windowBox = [NSMutableArray array];
  for (NSDictionary *definition in definitons) {
    UIAElement *mockWindow = [self _mockElementFromDefinition:definition];
    [windowBox addObject:mockWindow];
  }

  id mockApp = [OCMockObject partialMockForObject:[[UIAApplication alloc] init]];
  [[[mockApp stub] andReturn:windowBox.copy] windows];
  [[[mockApp stub] andReturn:windowBox.copy] elements];
  self.mockApplication = mockApp;

  [self.mockTarget stopMocking];
  self.mockTarget = [OCMockObject mockForClass:[UIATarget class]];
  [[[self.mockTarget stub] andReturn:self.mockTarget] localTarget];
  [[[self.mockTarget stub] andReturn:mockApp] frontMostApp];
}


- (UIAElement *)_mockElementFromDefinition:(NSDictionary *)definition
{
  UIAElement *element = [[NSClassFromString(definition[@"class"]) alloc] init];
  id elementMock = [OCMockObject partialMockForObject:element];

  NSArray *childElements = definition[@"elements"];
  if ([childElements count]) {
    NSMutableArray *mockChildren = [NSMutableArray array];

    for (NSDictionary *childDefinition in childElements) {
      [mockChildren addObject:[self _mockElementFromDefinition:childDefinition]];
    }
    [[[elementMock stub] andReturn:mockChildren] elements];
  }

  [[[elementMock stub] andReturn:definition[@"class"]] className];
  if (definition[@"name"]) {
    [[[elementMock stub] andReturn:definition[@"name"]] name];
  }
  if (definition[@"value"]) {
    [[[elementMock stub] andReturn:definition[@"value"]] value];
  }
  if (definition[@"label"]) {
    [[[elementMock stub] andReturn:definition[@"label"]] label];
  }
  if (definition[@"identifier"]) {
    [[[elementMock stub] andReturn:definition[@"identifier"]] identifier];
  }
  return elementMock;
}

- (void)fixUpAlerts
{
  id alertMock = [[self.mockApplication elements][0] elements][0];
  [[[alertMock stub] andReturn:[alertMock childrenOfClassName:@"UIAButton"]] buttons];
}

@end
