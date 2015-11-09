
@protocol FBElementCache;

@interface FBSession ()
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, copy, readwrite) NSString *activeSessionIdentifier;
@property (nonatomic, strong, readwrite) id <FBElementCache> elementCache;

/**
 Sets session as current session
 */
+ (void)markSessionActive:(FBSession *)session;

@end
