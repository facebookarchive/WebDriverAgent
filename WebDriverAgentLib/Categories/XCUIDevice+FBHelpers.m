/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIDevice+FBHelpers.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#include <notify.h>
#import <objc/runtime.h>

#import "FBSpringboardApplication.h"
#import "FBErrorBuilder.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "FBXCodeCompatibility.h"

#import "XCUIDevice.h"
#import "XCAXClient_iOS.h"

static const NSTimeInterval FBHomeButtonCoolOffTime = 1.;
static const NSTimeInterval FBScreenLockTimeout = 5.;

@implementation XCUIDevice (FBHelpers)

static bool fb_isLocked;

+ (void)load
{
  [self fb_registerAppforDetectLockState];
}

+ (void)fb_registerAppforDetectLockState
{
  int notify_token;
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wstrict-prototypes"
  notify_register_dispatch("com.apple.springboard.lockstate", &notify_token, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token) {
    uint64_t state = UINT64_MAX;
    notify_get_state(token, &state);
    fb_isLocked = state != 0;
  });
  #pragma clang diagnostic pop
}

- (BOOL)fb_goToHomescreenWithError:(NSError **)error
{
  [self pressButton:XCUIDeviceButtonHome];
  // This is terrible workaround to the fact that pressButton:XCUIDeviceButtonHome is not a synchronous action.
  // On 9.2 some first queries  will trigger additional "go to home" event
  // So if we don't wait here it will be interpreted as double home button gesture and go to application switcher instead.
  // On 9.3 pressButton:XCUIDeviceButtonHome can be slightly delayed.
  // Causing waitUntilApplicationBoardIsVisible not to work properly in some edge cases e.g. like starting session right after this call, while being on home screen
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBHomeButtonCoolOffTime]];
  if (![[FBSpringboardApplication fb_springboard] fb_waitUntilApplicationBoardIsVisible:error]) {
    return NO;
  }
  return YES;
}

- (BOOL)fb_lockScreen:(NSError **)error
{
  if (fb_isLocked) {
    return YES;
  }
  [self pressLockButton];
  return [[[[FBRunLoopSpinner new]
            timeout:FBScreenLockTimeout]
           timeoutErrorMessage:@"Timed out while waiting until the screen gets locked"]
          spinUntilTrue:^BOOL{
            return fb_isLocked;
          } error:error];
}

- (BOOL)fb_isScreenLocked
{
  return fb_isLocked;
}

- (BOOL)fb_unlockScreen:(NSError **)error
{
  if (!fb_isLocked) {
    return YES;
  }
  [self pressButton:XCUIDeviceButtonHome];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBHomeButtonCoolOffTime]];
  if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
    [[FBApplication fb_activeApplication] swipeRight];
  } else {
    [self pressButton:XCUIDeviceButtonHome];
  }
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBHomeButtonCoolOffTime]];
  return [[[[FBRunLoopSpinner new]
            timeout:FBScreenLockTimeout]
           timeoutErrorMessage:@"Timed out while waiting until the screen gets unlocked"]
          spinUntilTrue:^BOOL{
            return !fb_isLocked;
          } error:error];
}

- (NSData *)fb_screenshotWithError:(NSError*__autoreleasing*)error
{
  id xcScreen = NSClassFromString(@"XCUIScreen");
  if (nil == xcScreen) {
    NSData *result = [[XCAXClient_iOS sharedClient] screenshotData];
    if (nil == result) {
      if (error) {
        *error = [[FBErrorBuilder.builder withDescription:@"Cannot take a screenshot of the current screen state"] build];
      }
      return nil;
    }
    return result;
  }
  
  id mainScreen = [xcScreen valueForKey:@"mainScreen"];
  FBApplication *activeApplication = FBApplication.fb_activeApplication;
  UIInterfaceOrientation orientation = activeApplication.interfaceOrientation;
  SEL mSelector = NSSelectorFromString(@"screenshotDataForQuality:rect:error:");
  NSMethodSignature *mSignature = [mainScreen methodSignatureForSelector:mSelector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:mSignature];
  [invocation setTarget:mainScreen];
  [invocation setSelector:mSelector];
  // https://developer.apple.com/documentation/xctest/xctimagequality?language=objc
  // Select lower quality, since XCTest crashes randomly if the maximum quality (zero value) is selected
  // and the resulting screenshot does not fit the memory buffer preallocated for it by the operating system
  NSUInteger quality = 1;
  [invocation setArgument:&quality atIndex:2];
  CGSize screenSize = FBAdjustDimensionsForApplication(activeApplication.frame.size, orientation);
  CGRect screenRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
  [invocation setArgument:&screenRect atIndex:3];
  [invocation setArgument:&error atIndex:4];
  [invocation invoke];
  NSData __unsafe_unretained *imageData;
  [invocation getReturnValue:&imageData];
  if (nil == imageData) {
    return nil;
  }
  return FBAdjustScreenshotOrientationForApplication(imageData, orientation);
}

- (BOOL)fb_fingerTouchShouldMatch:(BOOL)shouldMatch
{
  const char *name;
  if (shouldMatch) {
    name = "com.apple.BiometricKit_Sim.fingerTouch.match";
  } else {
    name = "com.apple.BiometricKit_Sim.fingerTouch.nomatch";
  }
  return notify_post(name) == NOTIFY_STATUS_OK;
}

- (NSString *)fb_wifiIPAddress
{
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  int success = getifaddrs(&interfaces);
  if (success != 0) {
    freeifaddrs(interfaces);
    return nil;
  }

  NSString *address = nil;
  temp_addr = interfaces;
  while(temp_addr != NULL) {
    if(temp_addr->ifa_addr->sa_family != AF_INET) {
      temp_addr = temp_addr->ifa_next;
      continue;
    }
    NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];
    if(![interfaceName containsString:@"en"]) {
      temp_addr = temp_addr->ifa_next;
      continue;
    }
    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
    break;
  }
  freeifaddrs(interfaces);
  return address;
}

- (BOOL)fb_openUrl:(NSString *)url error:(NSError **)error
{
  NSURL *parsedUrl = [NSURL URLWithString:url];
  if (nil == parsedUrl) {
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"'%@' is not a valid URL", url]
            buildError:error];
  }
  
  id siriService = [self valueForKey:@"siriService"];
  if (nil != siriService) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [siriService performSelector:NSSelectorFromString(@"activateWithVoiceRecognitionText:")
                      withObject:[NSString stringWithFormat:@"Open {%@}", url]];
#pragma clang diagnostic pop
    return YES;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // The link never gets opened by this method: https://forums.developer.apple.com/thread/25355
  if (![[UIApplication sharedApplication] openURL:parsedUrl]) {
#pragma clang diagnostic pop
    return [[[FBErrorBuilder builder]
             withDescriptionFormat:@"The URL %@ cannot be opened", url]
            buildError:error];
  }
  return YES;
}

@end
