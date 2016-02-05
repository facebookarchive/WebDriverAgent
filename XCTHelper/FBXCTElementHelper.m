#import <libkern/OSAtomic.h>
#import <XCTHelper/FBXCTElementHelper.h>
#import "XCTestDriver.h"

@implementation FBXCTElementHelper
+ (BOOL)typeText:(NSString *)text error:(NSError **)error
{
    __block volatile uint32_t didFinishTyping = 0;
    __block BOOL didSucceed = NO;
    __block NSError *innerError;
    [[XCTestDriver sharedTestDriver].managerProxy _XCT_sendString:text completion:^(NSError *typingError){
        didSucceed = (typingError == nil);
        innerError = typingError;
        OSAtomicOr32Barrier(1, &didFinishTyping);
    }];
    while (!didFinishTyping) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    if (error) {
        *error = innerError;
    }
    return didSucceed;
}
@end
