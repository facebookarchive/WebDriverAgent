#import <Foundation/Foundation.h>

/**
 An interface to the application stub's Info.plist.
 */
@interface CBXInfoPlist : NSObject

/**
 Returns the CFBundleName.
 */
- (NSString *)bundleName;

/**
 Returns the CFBundleIdentifier.
 */
- (NSString *)bundleIdentifier;

/**
 Returns the CFBundleVersion - AKA the build version.
 */
- (NSString *)bundleVersion;

/**
 Returns the CFBundleShortVersionString - AKA the marketing version.
 */
- (NSString *)bundleShortVersion;

/**
 Returns a dictionary of version information.
 */
- (NSDictionary *)versionInfo;

@end
