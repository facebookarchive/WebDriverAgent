
#import <Foundation/Foundation.h>

@class CBXSpringBoardAlert;

/**
 * An interface to the SpringBoard alerts that can be dismissed automatically.
 *
 * This is a singleton class.  Calling `init` will raise an exception.
 */
@interface CBXSpringBoardAlerts : NSObject

/**
 * A singleton for reasoning about SpringBoard alerts
 *
 * @return the SpringBoardAlerts instance.
 */
+ (CBXSpringBoardAlerts *)shared;

/**
 * Returns a SpringBoardAlert if the the alertTitle matches one of the known
 * alerts. If the alert title matches no known alert, this method returns nil.
 * @param alertTitle The title of the alert; alert.label
 * @return a SpringBoardAlert or nil
 */
- (CBXSpringBoardAlert *)alertMatchingTitle:(NSString *)alertTitle;

@end
