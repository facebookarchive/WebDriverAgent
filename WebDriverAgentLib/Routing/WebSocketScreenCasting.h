//
//  WebSocketScreenCasting.h
//  WebDriverAgentLib
//
//  Created by SHUBHANKAR YASH on 11/01/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketIO/SocketIO-Swift.h>
#import <objc/runtime.h>
#import "FBApplication.h"
#import "FBResponseJSONPayload.h"
#import "FBScreenshotCommands.h"

@interface WebSocketScreenCasting : NSObject

-(void) setSocketConnected: (BOOL) isSocketConnected;
-(void) startScreeing: (SocketIOClient*) clientSocket;

@end
