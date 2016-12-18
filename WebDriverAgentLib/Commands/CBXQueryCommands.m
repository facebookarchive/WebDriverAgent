
#import "CBXQueryCommands.h"
#import "CBXAlertHandler.h"
#import "CBXJSONUtils.h"

@implementation CBXQueryCommands
+ (NSArray *)routes
{
    return
    @[
      [[FBRoute GET:CBXRoute(@"/springboard-alert")].withCBXSession respondWithTarget:self
                                                                               action:@selector(handleSpringboardAlert:)]
      ];
}

+ (id<FBResponsePayload>)handleSpringboardAlert:(FBRouteRequest *)request {
    FBAlert *alert = [CBXAlertHandler alertHandler].alert;
    NSArray *results = @[];
    if (alert.springboardAlertIsPresent) {
        results = @[[CBXJSONUtils elementToJSON:alert.springboardAlertElement]];
    }
    return CBXResponseWithJSON(@{@"result" : results});
}
@end
