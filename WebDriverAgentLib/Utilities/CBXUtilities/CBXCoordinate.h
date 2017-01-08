
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CBXJSONUtils.h"

/**
A convenience class for representing (x, y) coordinates.
 
 This class wraps the raw input values so as to provide
 a uniform representation of a variety of coordinate formats.
 */
@interface CBXCoordinate : NSObject

- (float)x;
- (float)y;

/**
CGPoint representation of the Coordinate contents
 */
- (CGPoint)cgpoint;
/**
 Instantiate using a raw CGPoint. When used in this way, 
 Coordinate become merely a Objective-C wrapper for CGPoint.
 
 @param raw A raw x, y point
 */
+ (instancetype)fromRaw:(CGPoint)raw;

/**
 Instantiate using coordinate json which can take one of 
 the following forms:
 
    [ x, y ]
    OR
    { "x" : x, "y" : y }
 
 @param json JSON coordinate input
 @exception InvalidArgumentException Thrown if `json` input doesn't match one of 
 the above formats
 */
+ (instancetype)withJSON:(id)json;
@end
