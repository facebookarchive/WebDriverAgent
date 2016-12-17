
#import <Foundation/Foundation.h>

#import <WebDriverAgentLib/FBCommandHandler.h>
#import "FBApplication.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "XCUIDevice.h"
#import "XCUIDevice+FBHealthCheck.h"

#import "CBXMacros.h"

@interface CBXCommands : NSObject/* Do not implement FBCommandHandler */
+ (XCUICoordinate *)tapCoordinateForX:(CGFloat)x y:(CGFloat)y;
+ (XCUIElement *)elementAtPoint:(CGPoint)point error:(NSError **)e;
+ (XCUIElement *)elementFromSpecifiers:(NSDictionary *)specifiers;
@end
