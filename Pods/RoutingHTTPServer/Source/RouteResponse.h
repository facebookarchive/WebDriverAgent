#import <Foundation/Foundation.h>
#import "HTTPResponse.h"
@class HTTPConnection;
@class HTTPResponseProxy;

@interface RouteResponse : NSObject

@property (nonatomic, assign, readonly) HTTPConnection *connection;
@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, strong) NSObject<HTTPResponse> *response;
@property (nonatomic, readonly) NSObject<HTTPResponse> *proxiedResponse;
@property (nonatomic) NSInteger statusCode;

- (id)initWithConnection:(HTTPConnection *)theConnection;
- (void)setHeader:(NSString *)field value:(NSString *)value;
- (void)respondWithString:(NSString *)string;
- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)respondWithData:(NSData *)data;
- (void)respondWithFile:(NSString *)path;
- (void)respondWithFile:(NSString *)path async:(BOOL)async;

@end
