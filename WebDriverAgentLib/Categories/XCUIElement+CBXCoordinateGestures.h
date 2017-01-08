
#import "XCUIElement+FBTap.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (CBXCoordinateGestures)

/**
 */
- (BOOL)cbx_tapAtCoordinate:(CGPoint)point withError:(NSError **)error;

/**
 */
- (BOOL)cbx_twoFingerTapAtCoordinate:(CGPoint)point withError:(NSError **)error;

- (BOOL)cbx_pinchAtCoordinate:(CGPoint)point
                        scale:(double)scale
                     velocity:(double)velocity
                    withError:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
