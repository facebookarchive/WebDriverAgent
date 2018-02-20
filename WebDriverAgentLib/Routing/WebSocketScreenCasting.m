//
//  WebSocketScreenCasting.m
//  WebDriverAgentLib
//
//  Created by SHUBHANKAR YASH on 11/01/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "WebSocketScreenCasting.h"
#import "XCUIDevice+FBHelpers.h"

@interface WebSocketScreenCasting()
@property (nonatomic, assign) BOOL isSocketConnected;
@property (nonatomic, assign) NSString* prevScreenShotData;
@property (nonatomic, assign) NSData* rawPrevScreenShotData;

@end


@implementation WebSocketScreenCasting

-(void) setSocketConnected: (BOOL) isSocketConnected {
  self.isSocketConnected = isSocketConnected;
}

-(void) pushScreenShot:(SocketIOClient*) clientSocket andOrientation:(UIInterfaceOrientation) orientation andScreenWidth:(CGFloat) screenWidth andScreenHeight:(CGFloat) screenHeight {
  FBResponseJSONPayload *fbJSONPayload = [FBScreenshotCommands handleGetScreenshotWithScreenMeta:orientation andScreenWidth:screenWidth andScreenHeight:screenHeight andPrevScreenData:self.prevScreenShotData];
  if(fbJSONPayload != nil) {
    self.prevScreenShotData = [[[fbJSONPayload dictionary]objectForKey:@"value"]objectForKey:@"base64EncodedImage"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fbJSONPayload.dictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSArray *dataArray = [[NSArray alloc] initWithObjects:jsonData, nil];
    [clientSocket emit:@"screenShot" with: dataArray];
  }
}

-(void) pushRawScreenShot:(SocketIOClient*) clientSocket andOrientation:(UIInterfaceOrientation) orientation andScreenWidth:(CGFloat) screenWidth andScreenHeight:(CGFloat) screenHeight {
  NSError *error;
  NSData *screenData = [[XCUIDevice sharedDevice] fb_screenshotWithError:&error withOrientation:orientation andScreenWidth:screenWidth andScreenHeight:screenHeight];
  if(self.rawPrevScreenShotData != nil && [self.rawPrevScreenShotData isEqualToData:screenData]) {
    // Do nothing as the previous screenshot is same as current.
  }
  else {
    self.rawPrevScreenShotData = screenData;
    NSArray *dataArray = [[NSArray alloc] initWithObjects:screenData, nil];
    [clientSocket emit:@"rawScreenShot" with: dataArray];
  }
}

-(void) startScreeing: (SocketIOClient*) clientSocket {
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
  UIInterfaceOrientation interfaceOrientation = FBApplication.fb_activeApplication.interfaceOrientation;
  CGSize screenSize = FBApplication.fb_activeApplication.frame.size;
  CGFloat width = screenSize.width;
  CGFloat height = screenSize.height;
  
  __weak WebSocketScreenCasting *weakSelf = self;
  dispatch_async(queue, ^{
    while(weakSelf.isSocketConnected) {
      WebSocketScreenCasting *strongSelf = weakSelf;
      //[strongSelf pushScreenShot: clientSocket andOrientation:interfaceOrientation andScreenWidth:width andScreenHeight:height];
      [strongSelf pushRawScreenShot: clientSocket andOrientation:interfaceOrientation andScreenWidth:width andScreenHeight:height];
    }
    self.prevScreenShotData = nil;
    self.rawPrevScreenShotData = nil;
  });
}

@end
