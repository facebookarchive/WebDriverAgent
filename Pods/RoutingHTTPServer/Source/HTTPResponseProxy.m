#import "HTTPResponseProxy.h"

@implementation HTTPResponseProxy

@synthesize response;
@synthesize status;

- (NSInteger)status {
	if (status != 0) {
		return status;
	} else if ([response respondsToSelector:@selector(status)]) {
		return [response status];
	}

	return 200;
}

- (void)setStatus:(NSInteger)statusCode {
	status = statusCode;
}

- (NSInteger)customStatus {
	return status;
}

// Implement the required HTTPResponse methods
- (UInt64)contentLength {
	if (response) {
		return [response contentLength];
	} else {
		return 0;
	}
}

- (UInt64)offset {
	if (response) {
		return [response offset];
	} else {
		return 0;
	}
}

- (void)setOffset:(UInt64)offset {
	if (response) {
		[response setOffset:offset];
	}
}

- (NSData *)readDataOfLength:(NSUInteger)length {
	if (response) {
		return [response readDataOfLength:length];
	} else {
		return nil;
	}
}

- (BOOL)isDone {
	if (response) {
		return [response isDone];
	} else {
		return YES;
	}
}

// Forward all other invocations to the actual response object
- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([response respondsToSelector:[invocation selector]]) {
		[invocation invokeWithTarget:response];
	} else {
		[super forwardInvocation:invocation];
	}
}

- (BOOL)respondsToSelector:(SEL)selector {
	if ([super respondsToSelector:selector])
		return YES;

	return [response respondsToSelector:selector];
}

@end

