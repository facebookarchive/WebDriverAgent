/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
#import "FBScreenshotCommands.h"
#import "XCUIDevice+FBHelpers.h"
#import "FBApplication.h"
#import "FBMathUtils.h"

static const XCUIApplication *app;
static UIInterfaceOrientation lastScreenOrientation;
static CGSize lastScreenSize;
static XCUIScreen *mainScreen;
static NSString *height,*width,*orientation;

@interface ScreenShotWithMeta : NSObject
@property (nonatomic) UIInterfaceOrientation orientation;
@property (nonatomic,strong) NSString *screenshot;
@property (nonatomic) int width, height;
@end

@implementation ScreenShotWithMeta
@end

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/screenshot"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshot:)],
    [[FBRoute GET:@"/screenshot"] respondWithTarget:self action:@selector(handleGetScreenshot:)],
    [[FBRoute GET:@"/screenshotWithScreenMeta"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshotWithScreenMeta:)],
    [[FBRoute GET:@"/screenshotWithScreenMeta"] respondWithTarget:self action:@selector(handleGetScreenshotWithScreenMeta:)],
  ];
}

+ (NSString*) getScreenData {
  NSTimeInterval fnStartTime = [[NSDate date] timeIntervalSince1970]*1000;
  NSError *error;
  
  //NSTimeInterval screenShotStartTime = [[NSDate date] timeIntervalSince1970]*1000;
  
  NSData *screenshotData = [[XCUIDevice sharedDevice] fb_screenshotWithError:&error];
  
  //NSTimeInterval screenShotEndTime = [[NSDate date] timeIntervalSince1970]*1000;
  
 // NSLog(@"ScreenShot time : %f",(screenShotEndTime - screenShotStartTime));
  
  if (nil == screenshotData) {
    return nil;
  }
  
  //NSTimeInterval screenShotConvertStartTime = [[NSDate date] timeIntervalSince1970]*1000;
  
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  
  //NSTimeInterval screenShotConvertEndTime = [[NSDate date] timeIntervalSince1970]*1000;
  //NSLog(@"ScreenShot convert time : %f",(screenShotConvertEndTime - screenShotConvertStartTime));
  
  NSTimeInterval fnEndTime = [[NSDate date] timeIntervalSince1970]*1000;
  
  NSLog(@"ScreenShot Function time  : %f",(fnEndTime - fnStartTime));
  
  return screenshot;
}

#pragma mark - Commands
+ (id<FBResponsePayload>)handleGetScreenshot:(FBRouteRequest *)request
{
  return FBResponseWithObject([self getScreenData]);
}

+ (id<FBResponsePayload>)handleGetScreenshotWithScreenMeta:(FBRouteRequest *)request
{
  if(app == nil) {
    app = FBApplication.fb_activeApplication;
  }
  
  if(CGSizeEqualToSize(CGSizeZero, lastScreenSize) || (lastScreenOrientation != app.interfaceOrientation) ) {
    lastScreenOrientation = app.interfaceOrientation;
    lastScreenSize = FBAdjustDimensionsForApplication(app.frame.size, app.interfaceOrientation);
    height = [NSString stringWithFormat:@"%.0f", lastScreenSize.height];
    width = [NSString stringWithFormat:@"%.0f", lastScreenSize.width];
    orientation = [NSString stringWithFormat:@"%.0ld", (long)lastScreenOrientation];
  }
  
  NSDictionary *screenShotWithMeta = @{
                                       @"height":height,
                                       @"width":width,
                                       @"orientation":orientation,
                                       @"base64EncodedImage":[self getScreenData]
                                    };
  return FBResponseWithObject(screenShotWithMeta);
}

@end

