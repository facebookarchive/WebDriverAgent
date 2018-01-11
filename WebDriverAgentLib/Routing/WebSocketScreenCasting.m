//
//  WebSocketScreenCasting.m
//  WebDriverAgentLib
//
//  Created by SHUBHANKAR YASH on 11/01/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "WebSocketScreenCasting.h"

@interface WebSocketScreenCasting()
@property (nonatomic, assign) BOOL isSocketConnected;
@end


@implementation WebSocketScreenCasting

-(void) setSocketConnected: (BOOL) isSocketConnected {
  self.isSocketConnected = isSocketConnected;
}

-(void) pushScreenShot:(SocketIOClient*) clientSocket andOrientation:(UIInterfaceOrientation) orientation andScreenWidth:(CGFloat) screenWidth andScreenHeight:(CGFloat) screenHeight {
  FBResponseJSONPayload *fbJSONPayload = [FBScreenshotCommands handleGetScreenshotWithScreenMeta:orientation andScreenWidth:screenWidth andScreenHeight:screenHeight];
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fbJSONPayload.dictionary
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:nil];
  NSArray *dataArray = [[NSArray alloc] initWithObjects:jsonData, nil];
  [clientSocket emit:@"screenShot" with: dataArray];
}

-(void) startScreeing: (SocketIOClient*) clientSocket {
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
  UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
  CGSize screenSize = FBApplication.fb_activeApplication.frame.size;
  CGFloat width = screenSize.width;
  CGFloat height = screenSize.height;
  
  __weak WebSocketScreenCasting *weakSelf = self;
  dispatch_async(queue, ^{
    while(weakSelf.isSocketConnected) {
      WebSocketScreenCasting *strongSelf = weakSelf;
      [strongSelf pushScreenShot: clientSocket andOrientation:interfaceOrientation andScreenWidth:width andScreenHeight:height];
    }
  });
}

@end
