
#import "CBXLSApplicationWorkspace.h"
#import "CBXSessionCommands.h"
#import "FBApplication.h"
#import "FBSession.h"

@implementation CBXSessionCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
    return
    @[
      //TODO: deprecate
      [[FBRoute POST:CBXRoute(@"/session")].withoutSession respondWithTarget:self
                                                                      action:@selector(handleCreateSession:)],
      [[FBRoute POST:CBXRoute(@"/launchApp")].withoutSession respondWithTarget:self
                                                                      action:@selector(handleCreateSession:)],
      
      //TODO: deprecate
      [[FBRoute DELETE:CBXRoute(@"/session")].withCBXSession respondWithTarget:self
                                                                        action:@selector(handleDeleteSession:)],
      [[FBRoute DELETE:CBXRoute(@"/terminateApp")].withCBXSession respondWithTarget:self
                                                                        action:@selector(handleDeleteSession:)],
      
      
      [[FBRoute POST:CBXRoute(@"/shutdown")].withoutSession respondWithTarget:self
                                                                       action:@selector(handleShutdown:)]
    ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)handleCreateSession:(FBRouteRequest *)request
{
    NSString *bundleID = request.arguments[@"bundleId"] ?:
                        request.arguments[@"bundleID"] ?:
                        request.arguments[@"bundle_id"];
    NSString *appPath = request.arguments[@"bundlePath"];
    if (!bundleID) {
        return CBXResponseWithErrorFormat(@"Must specify \"bundleID\"");
    }
    
    if (![CBXLSApplicationWorkspace applicationIsInstalled:bundleID]) {
        return CBXResponseWithErrorFormat(@"Application with identifier: %@ is not installed.",
                                          bundleID);
    }
    
    FBApplication *app = [[FBApplication alloc] initPrivateWithPath:appPath bundleID:bundleID];
    app.fb_shouldWaitForQuiescence = [request.arguments.allKeys containsObject:@"waitForQuiescence"] ?
                                    [request.arguments[@"waitForQuiescence"] boolValue] : YES;
    
    app.launchArguments = (NSArray<NSString *> *)request.arguments[@"launchArgs"] ?: @[];
    app.launchEnvironment = (NSDictionary <NSString *, NSString *> *)request.arguments[@"environment"] ?: @{};
    [app launch];
    
    if (app.processID == 0) {
        return FBResponseWithErrorFormat(@"Failed to launch %@ application", bundleID);
    }
    
    [FBSession sessionWithApplication:app];
    return CBXResponseWithStatus(@"launched!", nil);
}

+ (id<FBResponsePayload>)handleDeleteSession:(FBRouteRequest *)request {
    [[FBSession activeSession] kill];
    return CBXResponseWithStatus(@"dead", nil);
}
+ (id<FBResponsePayload>)handleShutdown:(FBRouteRequest *)request {
    //Want to make sure this route actually returns a response to the client before shutting down
    float nSecsToShutdown = 0.2f;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(nSecsToShutdown * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
    });

    return CBXResponseWithJSON(@{
                                 @"message" : @"Goodbye.",
                                 @"delay" : @(nSecsToShutdown)
                                 });
}
@end
