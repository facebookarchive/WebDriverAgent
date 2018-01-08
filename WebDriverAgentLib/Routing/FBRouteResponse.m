//
//  FBRouteResponse.m
//  WebDriverAgentLib
//
//  Created by SHUBHANKAR YASH on 08/01/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "FBRouteResponse.h"

@implementation FBRouteResponse

- (id)initWithRouteResponse:(RouteResponse *)response {
  self = [super init];
  self.response = response;
  return self;
}
- (id)initWithSocketAck:(SocketAckEmitter *)socketAck {
  self = [super init];
  self.socketAck = socketAck;
  return self;
}


- (void)setHeader:(NSString *)field value:(NSString *)value{
  if(self.response != nil) {
    [self.response setHeader:field value:value];
  } else if(self.socketAck != nil) {
  }
  
}
- (void)respondWithString:(NSString *)string{
  if(self.response != nil) {
    [self.response respondWithString:string];
  } else if(self.socketAck != nil) {
    NSArray *stringArray = [[NSArray alloc] initWithObjects:string, nil];
    [self.socketAck with:stringArray];
  }
  
}
- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding{
  if(self.response != nil) {
    [self.response respondWithString:string encoding:encoding];
  } else if(self.socketAck != nil) {
    NSArray *stringArray = [[NSArray alloc] initWithObjects:string, nil];
    [self.socketAck with:stringArray];
  }
}
- (void)respondWithData:(NSData *)data{
  if(self.response != nil) {
    [self.response respondWithData:data];
  } else if(self.socketAck != nil) {
    NSArray *dataArray = [[NSArray alloc] initWithObjects:data, nil];
    [self.socketAck with:dataArray];
  }
}
- (void)respondWithFile:(NSString *)path{
  if(self.response != nil) {
    [self.response respondWithFile:path];
  } else if(self.socketAck != nil) {
    NSArray *pathArray = [[NSArray alloc] initWithObjects:path, nil];
    [self.socketAck with:pathArray];
  }
}
- (void)respondWithFile:(NSString *)path async:(BOOL)async{
  if(self.response != nil) {
    [self.response respondWithFile:path async:async];
  } else if(self.socketAck != nil) {
    NSArray *pathArray = [[NSArray alloc] initWithObjects:path, nil];
    [self.socketAck with:pathArray];
  }
}

@end
