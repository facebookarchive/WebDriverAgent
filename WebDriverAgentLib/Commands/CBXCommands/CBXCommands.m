
#import "XCUICoordinate.h"
#import "XCTestDriver.h"
#import "XCUIElement.h"
#import "XCUIApplication.h"
#import "XCUIElementQuery.h"
#import "XCElementSnapshot.h"

#import "CBXCommands.h"
#import "CBXCoordinate.h"

#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"

@implementation CBXCommands

+ (XCUIElement *)elementFromSpecifiers:(NSDictionary *)specifiers {
    XCUIElement *element;
    if ([specifiers hasKey:@"uuid"]) {
        FBElementCache *elementCache = [FBSession activeSessionCache];
        element = [elementCache elementForUUID:specifiers[@"uuid"]];
    } else if ([specifiers hasKey:@"coordinate"]) {
        CBXCoordinate *coord = [CBXCoordinate withJSON:specifiers[@"coordinate"]];
        element = [CBXCommands elementAtPoint:coord.cgpoint error:nil];
    }
    return element;
}

+ (XCUICoordinate *)tapCoordinateForX:(CGFloat)x y:(CGFloat)y {
    if ([FBSession activeSession]) {
        XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:[FBSession activeSession].application
                                                               normalizedOffset:CGVectorMake(0, 0)];
        XCUICoordinate *tapCoordinate = [[XCUICoordinate alloc] initWithCoordinate:appCoordinate
                                                                      pointsOffset:CGVectorMake(x, y)];
    
        return tapCoordinate;
    }
    NSLog(@"WARN: Requested tap coordinate when active session is nil!");
    return nil;
}

+ (XCUIElement *)elementAtPoint:(CGPoint)point error:(NSError *__autoreleasing *)error  {
    __block XCUIElement *element = nil;
    __block XCAccessibilityElement *accEl = nil;
    __block NSError *outer;
    [FBRunLoopSpinner spinUntilCompletion:^(void (^ _Nonnull completion)()) {
        [[XCTestDriver sharedTestDriver].managerProxy _XCT_requestElementAtPoint:point
                                                                           reply:^(XCAccessibilityElement *axEl,
                                                                                   NSError *inner) {
                outer = inner;
                accEl = axEl;
                completion();
        }];
    }];
    XCElementSnapshot *snap = [[FBSession activeSession].application lastSnapshot];
    XCElementSnapshot *elSnap = [snap elementSnapshotMatchingAccessibilityElement:accEl];
    XCUIElementQuery *appQuery = [[FBSession activeSession].application.query descendantsMatchingType:elSnap.elementType];
    element = [appQuery _elementMatchingAccessibilityElementOfSnapshot:elSnap];
    
    //TODO: this can cause failures if no element found. Is it safe?
    [element resolve];
    if (error) {
        *error = outer;
    }
    return element;
}
@end
