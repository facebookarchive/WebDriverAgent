
#import "CBXHealthCommands.h"

@implementation CBXHealthCommands
+ (NSArray *)routes
{
    return
    @[
      [[FBRoute GET:CBXRoute(@"/health")].withoutSession respondWithTarget:self
                                                                      action:@selector(handleHealth:)],
      [[FBRoute GET:CBXRoute(@"/ping")].withoutSession respondWithTarget:self
                                                                      action:@selector(handlePing:)],
      [[FBRoute GET:CBXRoute(@"/status")].withoutSession respondWithTarget:self
                                                                      action:@selector(handleStatus:)],
      ];
}

+ (id<FBResponsePayload>)handleHealth:(FBRouteRequest *)request {
    return CBXResponseWithJSON(@{
                                 @"status" : @"DeviceAgent is ready and waiting."
                                 });
}

+ (id<FBResponsePayload>)handlePing:(FBRouteRequest *)request {
    return CBXResponseWithJSON(@{
                                 @"status" : @"honk"
                                 });
}

+ (id<FBResponsePayload>)handleStatus:(FBRouteRequest *)request {
    return CBXResponseWithJSON(@{
                                 @"status" : @"Calabash is ready and waiting."
                                 });
}

@end
