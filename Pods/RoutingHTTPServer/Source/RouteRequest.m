#import "RouteRequest.h"
#import "HTTPMessage.h"

@implementation RouteRequest {
	HTTPMessage *message;
}

@synthesize params;

- (id)initWithHTTPMessage:(HTTPMessage *)msg parameters:(NSDictionary *)parameters {
	if (self = [super init]) {
		params = parameters;
		message = msg;
	}
	return self;
}

- (NSDictionary *)headers {
	return [message allHeaderFields];
}

- (NSString *)header:(NSString *)field {
	return [message headerField:field];
}

- (id)param:(NSString *)name {
	return [params objectForKey:name];
}

- (NSString *)method {
	return [message method];
}

- (NSURL *)url {
	return [message url];
}

- (NSData *)body {
	return [message body];
}

- (NSString *)description {
	NSData *data = [message messageData];
	return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end
