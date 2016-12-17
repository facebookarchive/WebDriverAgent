#import "CBXInfoPlist.h"

@interface CBXInfoPlist ()

@property(strong, nonatomic, readonly) NSDictionary *infoDictionary;

- (NSString *)stringForKey:(NSString *) key;

@end

@implementation CBXInfoPlist

@synthesize infoDictionary = _infoDictionary;

- (NSDictionary *)infoDictionary {
    if (_infoDictionary) { return _infoDictionary; }
    _infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return _infoDictionary;
}

- (NSString *)stringForKey:(NSString *) key {
    NSString *value = self.infoDictionary[key];
    if (!value) { value = @""; }
    return value;
}

- (NSString *)bundleName {
    return [self stringForKey:@"CFBundleName"];
}

- (NSString *)bundleIdentifier {
    return [self stringForKey:@"CFBundleIdentifier"];
}

- (NSString *)bundleVersion {
    return [self stringForKey:@"CFBundleVersion"];
}

- (NSString *)bundleShortVersion {
    return [self stringForKey:@"CFBundleShortVersionString"];
}

- (NSDictionary *)versionInfo {
   return @{
            @"bundle_version" : [self bundleVersion],
            @"bundle_short_version" : [self bundleShortVersion],
            @"bundle_identifier" : [self bundleIdentifier],
            @"bundle_name" : [self bundleName],
            };
}

@end
