#import "RouteResponse.h"
#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "HTTPAsyncFileResponse.h"
#import "HTTPResponseProxy.h"

@implementation RouteResponse {
	NSMutableDictionary *headers;
	HTTPResponseProxy *proxy;
}

@synthesize connection;
@synthesize headers;

- (id)initWithConnection:(HTTPConnection *)theConnection {
	if (self = [super init]) {
		connection = theConnection;
		headers = [[NSMutableDictionary alloc] init];
		proxy = [[HTTPResponseProxy alloc] init];
	}
	return self;
}

- (NSObject <HTTPResponse>*)response {
	return proxy.response;
}

- (void)setResponse:(NSObject <HTTPResponse>*)response {
	proxy.response = response;
}

- (NSObject <HTTPResponse>*)proxiedResponse {
	if (proxy.response != nil || proxy.customStatus != 0 || [headers count] > 0) {
		return proxy;
	}

	return nil;
}

- (NSInteger)statusCode {
	return proxy.status;
}

- (void)setStatusCode:(NSInteger)status {
	proxy.status = status;
}

- (void)setHeader:(NSString *)field value:(NSString *)value {
	[headers setObject:value forKey:field];
}

- (void)respondWithString:(NSString *)string {
	[self respondWithString:string encoding:NSUTF8StringEncoding];
}

- (void)respondWithString:(NSString *)string encoding:(NSStringEncoding)encoding {
	[self respondWithData:[string dataUsingEncoding:encoding]];
}

- (void)respondWithData:(NSData *)data {
	self.response = [[HTTPDataResponse alloc] initWithData:data];
}

- (void)respondWithFile:(NSString *)path {
	[self respondWithFile:path async:NO];
}

- (void)respondWithFile:(NSString *)path async:(BOOL)async {
	if (async) {
		self.response = [[HTTPAsyncFileResponse alloc] initWithFilePath:path forConnection:connection];
	} else {
		self.response = [[HTTPFileResponse alloc] initWithFilePath:path forConnection:connection];
	}
}

@end
