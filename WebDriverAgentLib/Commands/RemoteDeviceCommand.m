//
//  RemoteDeviceCommand.m
//  WebDriverAgent
//
//  Created by icbc on 02/09/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

 

#import "RemoteDeviceCommand.h"

#import "FBApplication.h"
#import "FBSession.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"

#import "FBMathUtils.h"

#import "FBMacros.h"

#import "XCUIDevice+FBHelpers.h"
#import "XCUIElement+FBWebDriverAttributes.h"

#import "XCEventGenerator.h"


#import  <UIKit/UIKit.h>

@interface RemoteDeviceCommands ()
@end

@implementation RemoteDeviceCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    
    [[FBRoute POST:@"/wda/quickdrag"] respondWithTarget:self action:@selector(handleQuickDrag:)],
    
     [[FBRoute POST:@"/wda/quicktap"] respondWithTarget:self action:@selector(handleQuickTap:)],
    [[FBRoute POST:@"/screenshotpng"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshotPng:)],
    [[FBRoute POST:@"/screenshotpng"] respondWithTarget:self action:@selector(handleGetScreenshotPng:)],
    
    [[FBRoute POST:@"/screenshotjpg"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshotJpg:)],
    [[FBRoute POST:@"/screenshotjpg"] respondWithTarget:self action:@selector(handleGetScreenshotJpg:)],
    
      ];
}


#pragma mark - Commands


+ (id<FBResponsePayload>)handleQuickDrag:(FBRouteRequest *)request
{
  
  FBApplication *application = request.session.application;
  UIInterfaceOrientation orientation =application.interfaceOrientation;
  CGSize screenSize =  FBAdjustDimensionsForApplication (application.wdFrame.size, orientation);
  CGPoint startPoint = CGPointMake((CGFloat)[request.arguments[@"fromX"] doubleValue] * screenSize.width, (CGFloat)[request.arguments[@"fromY"] doubleValue] * screenSize.height);
  CGPoint endPoint = CGPointMake((CGFloat)[request.arguments[@"toX"] doubleValue] * screenSize.width, (CGFloat)[request.arguments[@"toY"] doubleValue] * screenSize.height);
  
  
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    /*
     Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
     even if the device is not in portait mode. That is why we need to recalculate them manually
     based on the current orientation value
     */
    
    
    
    
    startPoint = FBInvertPointForApplication(startPoint, application.wdFrame.size, orientation);
    endPoint = FBInvertPointForApplication(endPoint, application.wdFrame.size, orientation);
    // NSLog(@"quicktap2-6 FBElementCommand ,InvertPoint: x=%f, y=%f", tapPoint.x, tapPoint.y);
    
  }
  
  
  
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  
  
  XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
    /* if (commandError) {
     [FBLogger logFmt:@"Failed to perform tap: %@", commandError];
     }
     if (error) {
     *error = commandError;
     }
     didSucceed = (commandError == nil);
     completion();*/
  };
  
  XCEventGenerator *eventGenerator = [XCEventGenerator sharedGenerator];
  
  [ eventGenerator pressAtPoint:startPoint forDuration:duration liftAtPoint:endPoint velocity:1000 orientation:orientation name:@"drag" handler:handlerBlock ];
  
  return FBResponseWithOK();
}




+ (id<FBResponsePayload>)handleQuickTap:(FBRouteRequest *)request
{
  
  
  FBApplication * application =  request.session.application;
  UIInterfaceOrientation orientation =application.interfaceOrientation;
  
  CGSize adjustedSize = FBAdjustDimensionsForApplication (application.wdFrame.size, orientation);
  //NSLog(@"adjustedSize = %f, adjustedSize=%f", adjustedSize.width, adjustedSize.height);
  
  CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue]*adjustedSize.width, (CGFloat)[request.arguments[@"y"] doubleValue]*adjustedSize.height);
  
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    /*
     Since iOS 10.0 XCTest has a bug when it always returns portrait coordinates for UI elements
     even if the device is not in portait mode. That is why we need to recalculate them manually
     based on the current orientation value
     */
    
    tapPoint = FBInvertPointForApplication(tapPoint, application.wdFrame.size, orientation);
    
    
  }
  
  
  XCEventGeneratorHandler handlerBlock = ^(XCSynthesizedEventRecord *record, NSError *commandError) {
    /* if (commandError) {
     [FBLogger logFmt:@"Failed to perform tap: %@", commandError];
     }
     if (error) {
     *error = commandError;
     }
     didSucceed = (commandError == nil);
     completion();*/
  };
  
  XCEventGenerator *eventGenerator = [XCEventGenerator sharedGenerator];
  
  
  if ([eventGenerator respondsToSelector:@selector(tapAtTouchLocations:numberOfTaps:orientation:handler:)]) {
    
    [eventGenerator tapAtTouchLocations:@[[NSValue valueWithCGPoint:tapPoint]] numberOfTaps:1 orientation:orientation handler:handlerBlock];
    //NSLog(@"FBElementCommand ,hitpoint: x=%f, y=%f", tapPoint.x, tapPoint.y);
    
  }
  else {
    [eventGenerator tapAtPoint:tapPoint orientation:orientation handler:handlerBlock];
    //NSLog(@"FBElementCommand ,hitpoint: x=%f, y=%f", tapPoint.x, tapPoint.y);
    
  }
  return FBResponseWithOK();
}


+ (UIImage *)getScaledScreenshotImage:(CGFloat)imagex InterpolationQuality:(CGInterpolationQuality )interpolationQuality
{
  // get screenshot png image
    CGFloat imagey=0.0f;
  NSData* screenshotData = [XCUIDevice sharedDevice].fb_screenshot ;
  
  // store png image to UIImage
  UIImage *image    = [UIImage imageWithData: screenshotData];
  UIImage *scaledImage =image ;
  
  
 
  CGRect bounds;
 
  if (imagex != 0.0f ) {
    //if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown || orientation == UIInterfaceOrientationUnknown )
    if(image.size.height>image.size.width)
    {
      imagey = image.size.height * imagex / image.size.width ;
      bounds = CGRectMake(0, 0, imagex ,  imagey );
         //  NSLog(@"height>width: imagex = %f, imagey=%f, quality=%d",imagex, imagey,interpolationQuality  );
    }else{
      imagey = image.size.width * imagex / image.size.height ;
      bounds = CGRectMake(0, 0, imagey ,  imagex );
      
      //  NSLog(@"height<width  imagex = %f, imagey=%f, quality=%d "    ,imagex, imagey, interpolationQuality);
    }
    
     UIGraphicsBeginImageContext( bounds.size );
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, interpolationQuality);
    
    [image drawInRect:bounds];

    scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    
  }
  return scaledImage;
}

+ (id<FBResponsePayload>)handleGetScreenshotJpg:(FBRouteRequest *)request
{
  CGFloat imagex = [request.arguments[@"imagex"] intValue];
  CGFloat compressrate =(CGFloat ) [request.arguments[@"compressRate"] doubleValue];
  NSString* quality =(NSString *)  request.arguments[@"quality"]   ;
  
  CGInterpolationQuality interpolation =kCGInterpolationDefault ;
  
  if( [quality isEqualToString:@"HIGH"]){
    interpolation = kCGInterpolationHigh;
  }else if([ quality isEqualToString:@"LOW" ]){
    interpolation = kCGInterpolationLow;
  }else if( [ quality isEqualToString:@"Medium"]){
    interpolation = kCGInterpolationMedium;
  }else if( [ quality isEqualToString:@"NONE"]){
    interpolation = kCGInterpolationNone;
  }
  
  
  UIImage *scaledImage = [self getScaledScreenshotImage:imagex InterpolationQuality:interpolation];
 
  NSData * jpgData = UIImageJPEGRepresentation(scaledImage, compressrate);
  
  NSString *screenshot = [jpgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  
  return FBResponseWithObject(screenshot);
  
  
}


+ (id<FBResponsePayload>)handleGetScreenshotPng:(FBRouteRequest *)request
{
  
  CGFloat imagex = [request.arguments[@"imagex"] intValue];
  CGInterpolationQuality interpolation =kCGInterpolationDefault ;
  
   NSString* quality =(NSString* ) request.arguments[@"quality"] ;
 
  
  if( [quality isEqualToString:@"HIGH"]){
    interpolation = kCGInterpolationHigh;
  }else if([ quality isEqualToString:@"LOW" ]){
    interpolation = kCGInterpolationLow;
  }else if( [ quality isEqualToString:@"Medium"]){
    interpolation = kCGInterpolationMedium;
  }else if( [ quality isEqualToString:@"NONE"]){
    interpolation = kCGInterpolationNone;
  }
  
  UIImage *scaledImage = [self getScaledScreenshotImage:imagex InterpolationQuality:interpolation];
 
  NSData * pngData = UIImagePNGRepresentation(scaledImage);
  
  NSString *screenshot = [pngData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  
  return FBResponseWithObject(screenshot);
  
  
}
@end
