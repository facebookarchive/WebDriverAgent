
#import "CBXCommands.h"

@interface CBXGestureCommands : CBXCommands<FBCommandHandler>
+ (BOOL)handleTouch:(NSDictionary *)specifiers options:(NSDictionary *)options;
@end
