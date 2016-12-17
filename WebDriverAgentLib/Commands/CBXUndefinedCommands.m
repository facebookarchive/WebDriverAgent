
#import "CBXUndefinedCommands.h"

@implementation CBXUndefinedCommands
+ (BOOL)shouldRegisterAutomatically {
    return NO;
}

+ (NSArray *)routes {
    return @[
             [[FBRoute GET:CBXRoute(@"/*")].withCBXSession respondWithTarget:self
                                                                      action:@selector(handleUndefinedRoute:)],
             [[FBRoute POST:CBXRoute(@"/*")].withCBXSession respondWithTarget:self
                                                                      action:@selector(handleUndefinedRoute:)],
             [[FBRoute DELETE:CBXRoute(@"/*")].withCBXSession respondWithTarget:self
                                                                      action:@selector(handleUndefinedRoute:)],
             [[FBRoute PUT:CBXRoute(@"/*")].withCBXSession respondWithTarget:self
                                                                      action:@selector(handleUndefinedRoute:)],
             ];
}

//TODO: this used to return 404 status code
+ (id<FBResponsePayload>)handleUndefinedRoute:(FBRouteRequest *)request {
        return CBXResponseWithJSON(@{
                                     @"error" : @"unhandled endpoint",
                                     @"requestURL" : [request.URL.baseURL absoluteString] ?: @"?",
                                     @"requestEndpoint" : [request.URL relativePath] ?: @"?",
                                     @"requestMethod" : @"__deprecated",
                                     @"requestParameters" : request.parameters ?: @[],
                                     @"requestBody" : request.arguments ?: @{}
                                     });
}
@end
