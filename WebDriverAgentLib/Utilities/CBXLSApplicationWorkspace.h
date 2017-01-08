#import <Foundation/Foundation.h>

/**
 * Wrapper around private LSApplicationWorkspace.
 */
@interface CBXLSApplicationWorkspace : NSObject

/**
 * Returns YES if an application with bundle identifier is installed on the
 * target device.
 *
 * @param bundleIdentifier The application identifier to look for.
 *
 * @return YES if an application with bundleIdentifier is installed.
 */
+ (BOOL)applicationIsInstalled:(NSString *)bundleIdentifier;

@end
