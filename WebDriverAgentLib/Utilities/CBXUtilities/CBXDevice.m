#import "CBXDevice.h"
#import "CBXJSONUtils.h"
#import "CBXMacros.h"
#import <sys/utsname.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

NSString *const LPDeviceSimKeyModelIdentifier = @"SIMULATOR_MODEL_IDENTIFIER";
NSString *const LPDeviceSimKeyVersionInfo = @"SIMULATOR_VERSION_INFO";
NSString *const LPDeviceSimKeyIphoneSimulatorDevice_LEGACY = @"IPHONE_SIMULATOR_DEVICE";

@interface CBXDevice ()

@property(strong, nonatomic, readonly) NSDictionary *screenDimensions;
@property(assign, nonatomic, readonly) CGFloat sampleFactor;
@property(strong, nonatomic) NSDictionary *processEnvironment;
@property(strong, nonatomic) NSDictionary *formFactorMap;
@property(strong, nonatomic) NSDictionary *instructionSetMap;
@property(copy, nonatomic, readonly) NSString *physicalDeviceModelIdentifier;
@property(copy, nonatomic, readonly) NSString *deviceFamily;

- (id) init_private;

- (UIScreen *)mainScreen;
- (UIScreenMode *)currentScreenMode;
- (CGSize)sizeForCurrentScreenMode;
- (CGFloat)scaleForMainScreen;
- (CGFloat)heightForMainScreenBounds;
- (NSString *)physicalDeviceModelIdentifier;
- (NSString *)simulatorModelIdentfier;
- (NSString *)simulatorVersionInfo;
- (BOOL)isLetterBox;

@end

@implementation CBXDevice

@synthesize screenDimensions = _screenDimensions;
@synthesize sampleFactor = _sampleFactor;
@synthesize modelIdentifier = _modelIdentifier;
@synthesize formFactor = _formFactor;
@synthesize processEnvironment = _processEnvironment;
@synthesize formFactorMap = _formFactorMap;
@synthesize instructionSetMap = _instructionSetMap;
@synthesize armVersion = _armVersion;
@synthesize deviceFamily = _deviceFamily;
@synthesize name = _name;
@synthesize iOSVersion = _iOSVersion;
@synthesize physicalDeviceModelIdentifier = _physicalDeviceModelIdentifier;

- (id)init {
    @throw [NSException exceptionWithName:@"Cannot call init"
                                   reason:@"This is a singleton class"
                                 userInfo:nil];
}

+ (CBXDevice *)sharedDevice {
    static CBXDevice *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CBXDevice alloc] init_private];
    });
    return shared;
}

- (id)init_private {
    self = [super init];
    if (self) {
        // For memoizing.
        _sampleFactor = CGFLOAT_MAX;
    }
    return self;
}

#pragma mark - Convenience Methods for Testing

- (UIScreen *)mainScreen {
    return [UIScreen mainScreen];
}

- (UIScreenMode *)currentScreenMode {
    return [[self mainScreen] currentMode];
}

- (CGSize)sizeForCurrentScreenMode {
    return [self currentScreenMode].size;
}

- (CGFloat)scaleForMainScreen {
    return [[self mainScreen] scale];
}

- (CGFloat)heightForMainScreenBounds {
    return [[self mainScreen] bounds].size.height;
}

#pragma mark - iPhone 6 and 6 Plus Support

// http://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
// Thanks for the inspiration for iPhone 6 form factor sample.
- (CGFloat)sampleFactor {
    if (!float_eq(CGFLOAT_MAX, _sampleFactor)) { return _sampleFactor; }

    _sampleFactor = 1.0;

    UIScreen *screen = [UIScreen mainScreen];
    CGSize screenSize = screen.bounds.size;
    CGFloat screenHeight = MAX(screenSize.height, screenSize.width);
    CGFloat scale = screen.scale;

    CGFloat nativeScale = scale;
    if ([screen respondsToSelector:@selector(nativeScale)]) {
        nativeScale = screen.nativeScale;
    }

    CGFloat iphone6_zoom_sample = 1.171875;
    CGFloat iphone6p_zoom_sample = 0.96;

    UIScreenMode *screenMode = [screen currentMode];
    CGSize screenSizeForMode = screenMode.size;
    CGFloat pixelAspectRatio = screenMode.pixelAspectRatio;

    NSLog(@"         Form factor: %@", [self formFactor]);
    NSLog(@" Current screen mode: %@", screenMode);
    NSLog(@"Screen size for mode: %@", NSStringFromCGSize(screenSizeForMode));
    NSLog(@"       Screen height: %@", @(screenHeight));
    NSLog(@"        Screen scale: %@", @(scale));
    NSLog(@" Screen native scale: %@", @(nativeScale));
    NSLog(@"Pixel Aspect Ratio: %@", @(pixelAspectRatio));

    if ([self isIPhone6PlusLike]) {
        if (screenHeight == 568.0 && nativeScale > scale) { // native => 2.88
            NSLog(@"iPhone 6 Plus: Zoom display mode and app is not optimized for screen size - adjusting sampleFactor");
            _sampleFactor = iphone6p_zoom_sample;
        } else if (screenHeight == 667.0 && nativeScale <= scale) { // native => ???
            NSLog(@"iPhone 6 Plus: Zoomed display mode - sampleFactor remains the same");
        } else if (float_eq(screenHeight, 736) && nativeScale < scale) { // native => 2.61
            NSLog(@"iPhone 6 Plus: Standard Display and app is not optimized for screen size - sampleFactor remains the same");
        }
    } else if ([self isIPhone6Like]) {
        if (screenHeight == 568.0 && nativeScale <= scale) {
            NSLog(@"iPhone 6: application not optimized for screen size - adjusting sampleFactor");
            _sampleFactor = iphone6_zoom_sample;
        } else if (screenHeight == 568.0 && nativeScale > scale) {
            NSLog(@"iPhone 6: Zoomed display mode - sampleFactor remains the same");
        }
    }

    return _sampleFactor;
}

- (NSDictionary *)screenDimensions {
    if (_screenDimensions) { return _screenDimensions; }

    UIScreen *screen = [UIScreen mainScreen];
    UIScreenMode *screenMode = [screen currentMode];
    CGSize size = screenMode.size;
    CGFloat scale = screen.scale;

    CGFloat nativeScale = scale;
    if ([screen respondsToSelector:@selector(nativeScale)]) {
        nativeScale = screen.nativeScale;
    }

    _screenDimensions = @{
                          @"height" : @(size.height),
                          @"width" : @(size.width),
                          @"scale" : @(scale),
                          @"sample" : @([self sampleFactor]),
                          @"native_scale" : @(nativeScale)
                          };

    return _screenDimensions;
}

// http://www.everyi.com/by-identifier/ipod-iphone-ipad-specs-by-model-identifier.html
- (NSDictionary *)formFactorMap {
    if (_formFactorMap) { return _formFactorMap; }

    _formFactorMap =

    @{

      // iPhone 4/4s and iPod 4th
      @"iPhone3,1" : @"iphone 3.5in",
      @"iPhone3,3" : @"iphone 3.5in",
      @"iPhone4,1" : @"iphone 3.5in",
      @"iPod4,1"   : @"iphone 3.5in",

      // iPhone 5/5c/5s, iPod 5th + 6th, and 6se
      @"iPhone5,1" : @"iphone 4in",
      @"iPhone5,2" : @"iphone 4in",
      @"iPhone5,3" : @"iphone 4in",
      @"iPhone5,4" : @"iphone 4in",
      @"iPhone6,1" : @"iphone 4in",
      @"iPhone6,2" : @"iphone 4in",
      @"iPhone6,3" : @"iphone 4in",
      @"iPhone6,4" : @"iphone 4in",
      @"iPod5,1"   : @"iphone 4in",
      @"iPod6,1"   : @"iphone 4in",
      @"iPhone8,4" : @"iphone 4in",

      // iPhone 6/6s
      @"iPhone7,2" : @"iphone 6",
      @"iPhone8,1" : @"iphone 6",

      // iPhone 6+
      @"iPhone7,1" : @"iphone 6+",
      @"iPhone8,2" : @"iphone 6+",

      // iPhone 7/7+
      @"iPhone9,1" : @"iphone 6",
      @"iPhone9,3" : @"iphone 6",
      @"iPhone9,2" : @"iphone 6+",
      @"iPhone9,4" : @"iphone 6+",

      // iPad Pro 13in
      @"iPad6,7" : @"ipad pro",
      @"iPad6,8" : @"ipad pro",

      // iPad Pro 9in
      @"iPad6,3" : @"ipad pro",
      @"iPad6,4" : @"ipad pro"

      };

    return _formFactorMap;
}

// https://www.innerfence.com/howto/apple-ios-devices-dates-versions-instruction-sets
- (NSDictionary *)instructionSetMap {
    if (_instructionSetMap) { return _instructionSetMap; }

    _instructionSetMap =

    @{
      @"armv7" : @[
              // iPhone 4/4s and iPod 4th
              @"iPhone3,1",
              @"iPhone3,3",
              @"iPhone4,1",
              @"iPod4,1",
              @"iPod5,1",

              // iPad 2 and 3 and iPad Mini
              @"iPad2,1",
              @"iPad2,2",
              @"iPad2,3",
              @"iPad2,4",
              @"iPad2,5",
              @"iPad2,6",
              @"iPad2,7",
              @"iPad3,1",
              @"iPad3,2",
              @"iPad3,3",
              ],
      @"armv7s" : @[
              // iPhone 5/5c
              @"iPhone5,1",
              @"iPhone5,2",
              @"iPhone5,3",
              @"iPhone5,4",

              // iPad 4
              @"iPad3,4",
              @"iPad3,5",
              @"iPad3,6"
              ],

      @"arm64" : @[

              // iPhone 7/7+
              @"iPhone9,1",
              @"iPhone9,3",
              @"iPhone9,2",
              @"iPhone9,4",

              // iPhone 6/6s
              @"iPhone7,2",
              @"iPhone8,1",

              // iPhone 6+
              @"iPhone7,1",
              @"iPhone8,2",
              
              // iPad Pro 13in
              @"iPad6,7",
              @"iPad6,8",
              
              // iPad Pro 9in
              @"iPad6,3",
              @"iPad6,4",

              // iPhone 6se
              @"iPhone8,4",

              // iPod 6 and 7
              @"iPod6,1",
              @"iPod7,1",

              // iPhone 5s
              @"iPhone6,1",
              @"iPhone6,2",
              @"iPhone6,3",
              @"iPhone6,4",

              // iPad Air, Air2, mini Retina
              @"iPad4,1",
              @"iPad4,2",
              @"iPad4,4",
              @"iPad4,5",
              @"iPad4,6",
              @"iPad5,1",
              @"iPad5,2",
              @"iPad5,3",
              @"iPad5,4"
              ]
      };

    return _instructionSetMap;
}

- (NSString *)armVersion {
    if (_armVersion) { return _armVersion; }

    NSString *match = nil;
    NSString *model = [self modelIdentifier];
    NSDictionary *map = [self instructionSetMap];
    for(NSString *arch in [map allKeys]) {
        NSArray *models = map[arch];
        if ([models containsObject:model]) {
            match = arch;
            break;
        }
    }

    if (match) {
        _armVersion = match;
    } else {
        _armVersion = @"unknown";
    }
    return _armVersion;
}

- (NSDictionary *)processEnvironment {
    if (_processEnvironment) { return _processEnvironment; }
    _processEnvironment = [[NSProcessInfo processInfo] environment];
    return _processEnvironment;
}

- (NSString *)simulatorModelIdentfier {
    return [self.processEnvironment objectForKey:LPDeviceSimKeyModelIdentifier];
}

- (NSString *)simulatorVersionInfo {
    return [self.processEnvironment objectForKey:LPDeviceSimKeyVersionInfo];
}

- (NSString *)physicalDeviceModelIdentifier {
    if (_physicalDeviceModelIdentifier) { return _physicalDeviceModelIdentifier; }
    struct utsname systemInfo;
    uname(&systemInfo);
    _physicalDeviceModelIdentifier = @(systemInfo.machine);
    return _physicalDeviceModelIdentifier;
}

- (NSString *)deviceFamily {
    if (_deviceFamily) { return _deviceFamily; }
    _deviceFamily = [[UIDevice currentDevice] model];
    return _deviceFamily;
}

- (NSString *)name {
    if (_name) { return _name; }
    _name = [[UIDevice currentDevice] name];
    return _name;
}

- (NSString *)iOSVersion {
    if (_iOSVersion) { return _iOSVersion; }
    _iOSVersion = [[UIDevice currentDevice] systemVersion];
    return _iOSVersion;
}

// The hardware name of the device.
- (NSString *)modelIdentifier {
    if (_modelIdentifier) { return _modelIdentifier; }
    if ([self isSimulator]) {
        _modelIdentifier = [self simulatorModelIdentfier];
    } else {
        _modelIdentifier = [self physicalDeviceModelIdentifier];
    }
    return _modelIdentifier;
}

- (NSString *)formFactor {
    if (_formFactor) { return _formFactor; }

    NSString *modelIdentifier = [self modelIdentifier];
    NSString *value = [self.formFactorMap objectForKey:modelIdentifier];

    if (value) {
        _formFactor = value;
    } else {
        if ([self isIPad]) {
            _formFactor = @"ipad";
        } else {
            _formFactor = modelIdentifier;
        }
    }
    return _formFactor;
}

- (BOOL)isSimulator {
    return [self simulatorModelIdentfier] != nil;
}

- (BOOL)isPhysicalDevice {
    return ![self isSimulator];
}

- (BOOL)isIPhone6Like {
    return [[self formFactor] isEqualToString:@"iphone 6"];
}

- (BOOL)isIPhone6PlusLike {
    return [[self formFactor] isEqualToString:@"iphone 6+"];
}

- (BOOL)isIPad {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (BOOL)isIPadPro {
    return [[self formFactor] isEqualToString:@"ipad pro"];
}

- (BOOL)isIPhone4Like {
    return [[self formFactor] isEqualToString:@"iphone 3.5in"];
}

- (BOOL)isIPhone5Like {
    return [[self formFactor] isEqualToString:@"iphone 4in"];
}

- (BOOL)isLetterBox {
    CGFloat scale = [self scaleForMainScreen];
    if ([self isIPad] || [self isIPhone4Like] || scale != 2.0) {
        return NO;
    } else {
        return float_eq([self heightForMainScreenBounds] * scale, 960);
    }
}

- (BOOL)isArm64 {
    return [self.armVersion containsString:@"arm64"];
}

- (NSDictionary *)dictionaryRepresentation {
    return
    @{
      @"simulator" : @([self isSimulator]),
      @"physical_device" : @([self isPhysicalDevice]),
      @"iphone6" : @([self isIPhone6Like]),
      @"iphone6+" : @([self isIPhone6PlusLike]),
      @"ipad" : @([self isIPad]),
      @"ipad_pro" : @([self isIPadPro]),
      @"iphone4" : @([self isIPhone4Like]),
      @"iphone5" : @([self isIPhone5Like]),
      @"letter_box" : @([self isLetterBox]),
      @"screen" : [self screenDimensions],
      @"sample_factor" : @([self sampleFactor]),
      @"model_identifier" : [self modelIdentifier],
      @"form_factor" : [self formFactor],
      @"family" : [self deviceFamily],
      @"name" : [self name],
      @"ios_version" : [self iOSVersion],
      @"physical_device_model_identifier" : [self physicalDeviceModelIdentifier],
      @"arm_version" : [self armVersion]
      };
}

- (NSString *)JSONRepresentation {
    return [self dictionaryRepresentation].pretty;
}

@end
