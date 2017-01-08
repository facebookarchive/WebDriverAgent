#import "CBXLSApplicationWorkspace.h"

@implementation CBXLSApplicationWorkspace

//TODO: Does this actually work?
+ (BOOL)applicationIsInstalled:(NSString *)bundleIdentifier {
    Class klass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = [klass new];
    SEL selector = NSSelectorFromString(@"applicationIsInstalled:");

    NSMethodSignature *signature;
    signature = [klass instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation;

    invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = workspace;
    invocation.selector = selector;

    NSString *localCopy = [bundleIdentifier copy];
    [invocation setArgument:&localCopy atIndex:2];

    [invocation invoke];

    BOOL isInstalled = NO;
    char ref;
    [invocation getReturnValue:(void **) &ref];
    if (ref == (BOOL)1) {
        isInstalled = YES;
    }

    return isInstalled;
}

@end
