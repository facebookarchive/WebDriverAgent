#import <UIKit/UIKit.h>

extern NSString *const LPDeviceSimKeyModelIdentifier;
extern NSString *const LPDeviceSimKeyVersionInfo;
extern NSString *const LPDeviceSimKeyIphoneSimulatorDevice_LEGACY;

/**
 Runtime information about the device under test.

 This is a singleton class.  Calling `init` will raise an exception.
 */
@interface CBXDevice : NSObject

/**
 The model identifier e.g. iPhone8,4 => iPhone 6se
 */
@property(copy, nonatomic, readonly) NSString *modelIdentifier;

/**
 A description of the device form factor e.g. "iphone 4in" or "ipad pro"
 */
@property(copy, nonatomic, readonly) NSString *formFactor;

/**
 The name of the device as reported by Xcode, instruments, or iTunes.
 */
@property(copy, nonatomic, readonly) NSString *name;

/**
 The iOS version.
 */
@property(copy, nonatomic, readonly) NSString *iOSVersion;

/**
 The ARM version.
 */
@property(copy, nonatomic, readonly) NSString *armVersion;

/**
 CBXDevice is a singleton class.

 @return The single instance of CBXDevice.
 */
+ (CBXDevice *)sharedDevice;

/**
 @return True if the device under test is a simulator.
 */
- (BOOL)isSimulator;

/**
 @return True if the device under test is a physical device.
 */
- (BOOL)isPhysicalDevice;

/**
 @return True if the device is an iPhone 6 or iPhone 6s.
 */
- (BOOL)isIPhone6Like;

/**
 @return True if the device is an iPhone 6+ or iPhone 6s plus.
 */
- (BOOL)isIPhone6PlusLike;

/**
 @return True if the device an iPad.
 */
- (BOOL)isIPad;

/**
 @return True if the device is an iPad Pro.
 */
- (BOOL)isIPadPro;

/**
 @return True if the device is an iPhone 4 or iPhone 4s.
 */
- (BOOL)isIPhone4Like;

/**
 @return True if the device is an iPhone 5, 5c, 5s, or 6se.
 */
- (BOOL)isIPhone5Like;

/**
 @return True if the device is arm64
 */
- (BOOL)isArm64;

/**
 @return A dictionary describing the attributes of this device.
 */
- (NSDictionary *)dictionaryRepresentation;

@end
