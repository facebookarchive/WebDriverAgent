
#import "CBXMetaCommands.h"
#import "CBXInfoPlist.h"
#import "CBXDevice.h"

@implementation CBXMetaCommands

+ (NSArray *)routes {
    return @[
             [[FBRoute GET:CBXRoute(@"/sessionIdentifier")].withCBXSession respondWithTarget:self
                                                                           action:@selector(handleSessionIdentifier:)],
             [[FBRoute GET:CBXRoute(@"/pid")].withCBXSession respondWithTarget:self
                                                                           action:@selector(handlePid:)],
             [[FBRoute GET:CBXRoute(@"/device")].withoutSession respondWithTarget:self
                                                                           action:@selector(handleDeviceInfo:)],
             [[FBRoute GET:CBXRoute(@"/version")].withoutSession respondWithTarget:self
                                                                           action:@selector(handleVersion:)],
             [[FBRoute GET:CBXRoute(@"/arguments")].withCBXSession respondWithTarget:self
                                                                           action:@selector(handleArguments:)],
             [[FBRoute GET:CBXRoute(@"/environment")].withCBXSession respondWithTarget:self
                                                                           action:@selector(handleEnvironment:)],
             ];
}

+ (id<FBResponsePayload>)handleSessionIdentifier:(FBRouteRequest *)request {
    return CBXResponseWithJSON(@{@"sessionId" : [FBSession activeSession].identifier});
}

+ (id<FBResponsePayload>)handlePid:(FBRouteRequest *)request {
    NSString *pidString = [NSString stringWithFormat:@"%d", [FBSession activeSession].application.processID];
    return CBXResponseWithJSON(@{@"pid" : pidString});
}

+ (id<FBResponsePayload>)handleDeviceInfo:(FBRouteRequest *)request {
    NSDictionary *json = [[CBXDevice sharedDevice] dictionaryRepresentation];
    return CBXResponseWithJSON(json);
}

+ (id<FBResponsePayload>)handleVersion:(FBRouteRequest *)request {
    return CBXResponseWithJSON([[CBXInfoPlist new] versionInfo]);
}

+ (id<FBResponsePayload>)handleArguments:(FBRouteRequest *)request {
    NSArray *aut_arguments = @[];
    if ([FBSession activeSession].application) {
        aut_arguments = [[FBSession activeSession].application launchArguments];
    }
    
    NSArray *device_agent_arguments;
    device_agent_arguments = [[NSProcessInfo processInfo] arguments];
    
    NSDictionary *json;
    json = @{
             @"aut_arguments" : aut_arguments,
             @"device_agent_arguments" : device_agent_arguments };
    
    return CBXResponseWithJSON(json);
}

+ (id<FBResponsePayload>)handleEnvironment:(FBRouteRequest *)request {
    NSDictionary *aut_environment = @{};
    if ([FBSession activeSession].application) {
        aut_environment = [[FBSession activeSession].application launchEnvironment];
    }
    
    NSDictionary *device_agent_environment;
    device_agent_environment = [[NSProcessInfo processInfo] environment];
    
    NSDictionary *json;
    json = @{
             @"aut_environment" : aut_environment,
             @"device_agent_environment" : device_agent_environment };
    
    return CBXResponseWithJSON(json);
}

@end
