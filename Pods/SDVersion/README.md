<p align="center">
 <img src="https://dl.dropboxusercontent.com/s/bmfjwfe2ngnivwn/sdversion.png?dl=0" alt="SDVersion"/>
</p>

<p align="center">
    <a href="https://gitter.im/sebyddd/SDiPhoneVersion?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge">
        <img src="https://img.shields.io/badge/gitter-join%20chat-1dce73.svg"
             alt="Gitter">
    </a>
    <a href="http://sebastiandobrincu.com">
        <img src="https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS-D0547F.svg"
             alt="Platform">
    </a>
    <a href="http://sebastiandobrincu.com">
        <img src="http://img.shields.io/cocoapods/v/SDVersion.svg"
             alt="Cocoapods Version">
    </a>
</p>

Lightweight Cocoa library for detecting the running device's model and screen size.

With the newer  devices, developers have more work to do. This library simplifies their job by allowing them to get information about the running device and easily target the ones they want.

SDVersion supports iOS, watchOS, tvOS, and macOS. Browse through the implementation of each platform using the links below.

<p align="center">
	<a href="#ios">
        	<img src="https://dl.dropboxusercontent.com/s/ck42lqeda643v02/sdversion-ios.png?dl=0" alt="iOS">
	</a>
	<a href="#mac-os">
		<img src="https://dl.dropboxusercontent.com/s/2yhgx57v4alnzld/sdversion-mac.png?dl=0" alt="Mac">
	</a>
</p>

## How it works

```objective-c
      // Check for device model
      if ([SDVersion deviceVersion] == iPhone7)
           NSLog(@"You got the iPhone 7. Sweet 🍭!");
      else if ([SDVersion deviceVersion] == iPhone6SPlus)
           NSLog(@"iPhone 6S Plus? Bigger is better!");
      else if ([SDVersion deviceVersion] == iPadAir2)
      	   NSLog(@"You own an iPad Air 2 🌀!");

      // Check for device screen size
      if ([SDVersion deviceSize] == Screen4Dot7inch)
           NSLog(@"Your screen is 4.7 inches");

      // Check if screen is in zoom mode
      if ([SDVersion isZoomed])
      	   NSLog(@"Your device is in Zoom Mode 🔎");

      // Get device name
      NSLog(@"%@", [SDVersion deviceNameString]);
      /* e.g: Outputs 'iPhone 7 Plus' */

      // Check for iOS Version
      if ([SDVersion versionGreaterThanOrEqualTo:@"10"])
           NSLog(@"You are running iOS 10 or above!");
```

<p align="center">
 <a href="#how-it-works">
        	<img src="https://static1.squarespace.com/static/52428a0ae4b0c4a5c2a2cede/t/5479ce82e4b028a16123006d/1417268866072/Apple_Swift_Logo.png" alt="SDVersion Swift" width="40" height="40"/><br>
	</a>
Swift Version:
</p>
  

```swift
      // Check for device model
      if SDiOSVersion.deviceVersion() == .iPhone7 {
            print("You got the iPhone 7. Sweet 🍭!")
      }

      // Check for device screen size
      if SDiOSVersion.deviceSize() == .Screen3Dot5inch {
            print("Still on 3.5 inches!? 😮")
      }

      // Get device name
      print(SDiOSVersion.deviceNameString())
      /* e.g: Outputs 'iPhone 7 Plus' */

      // Check for iOS Version
      if SDiOSVersion.versionGreaterThan("10") {
            print("You are running iOS 10 or above!")
      }
```

## Add to your project

There are 2 ways you can add SDVersion to your project:

### Manual installation


 Simply import the 'SDVersion' into your project then import the following in the class you want to use it:
 ```objective-c
       #import "SDVersion.h"
 ```
 In Swift, you need to import in the bridging header the specific library version, not the library wrapper:
  ```objective-c
       #import "SDiOSVersion.h" // Or SDMacVersion.h
 ```

### Installation with CocoaPods

CocoaPods is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like SDVersion in your projects. See the "[Getting Started](http://guides.cocoapods.org/syntax/podfile.html)" guide for more information.

### Podfile
```ruby
        pod 'SDVersion'
```


## iOS

### Available methods
```objective-c
	+ (DeviceVersion)deviceVersion;
	+ (NSString *)deviceNameForVersion:(DeviceVersion)deviceVersion;
	+ (DeviceSize)resolutionSize;
	+ (DeviceSize)deviceSize;
	+ (NSString *)deviceSizeName:(DeviceSize)deviceSize;
	+ (NSString *)deviceNameString;
	+ (BOOL)isZoomed;
```
### Targetable models
	iPhone4
    iPhone4S
    iPhone5
    iPhone5C
    iPhone5S
    iPhone6
    iPhone6Plus
    iPhone6S
    iPhone6SPlus
    iPhoneSE
    iPhone7
    iPhone7Plus

    iPad1
    iPad2
    iPadMini
    iPad3
    iPad4
    iPadAir
    iPadMini2
    iPadAir2
    iPadMini3
    iPadMini4
    iPadPro9Dot7Inch
    iPadPro12Dot9Inch
    iPad5

	iPodTouch1Gen
    iPodTouch2Gen
    iPodTouch3Gen
    iPodTouch4Gen
    iPodTouch5Gen
    iPodTouch6Gen

    Simulator
### Targetable screen sizes
    Screen3Dot5inch
    Screen4inch
    Screen4Dot7inch
    Screen5Dot5inch
### Available iOS Version Finder methods
  ```objective-c
      + (BOOL)versionEqualTo:(NSString *)version;
      + (BOOL)versionGreaterThan:(NSString *)version;
      + (BOOL)versionGreaterThanOrEqualTo:(NSString *)version;
      + (BOOL)versionLessThan:(NSString *)version;
      + (BOOL)versionLessThanOrEqualTo:(NSString *)version;
  ```       

### Helpers
```objective-c
	  NSLog(@"%@", [SDVersion deviceVersionName:[SDVersion deviceVersion]]);
      /* e.g: Outputs 'iPad Air 2' */

      NSLog(@"%@", [SDVersion deviceSizeName:[SDVersion deviceSize]]);
      /* e.g: Outputs '4.7 inch' */
```
Or in Swift: 
```swift
      let deviceVersionName = SDiOSVersion.deviceVersionName(SDiOSVersion.deviceVersion())
      let deviceSizeName = SDiOSVersion.deviceSizeName(SDiOSVersion.deviceSize())    
```

## watchOS

### Available methods
```objective-c
    + (DeviceVersion)deviceVersion;
	+ (DeviceSize)deviceSize;
	+ (NSString *)deviceName;
```
### Targetable models
	Apple Watch 38mm
    Apple Watch 42mm
    Apple Watch 38mm Series 1
    Apple Watch 42mm Series 1
    Apple Watch 38mm Series 2
    Apple Watch 42mm Series 2

    Simulator

### Targetable screen sizes
    Screen38mm
    Screen42mm

### Available watchOS Version Finder methods
```objective-c
    + (BOOL)versionEqualTo:(NSString *)version;
    + (BOOL)versionGreaterThan:(NSString *)version;
    + (BOOL)versionGreaterThanOrEqualTo:(NSString *)version;
    + (BOOL)versionLessThan:(NSString *)version;
    + (BOOL)versionLessThanOrEqualTo:(NSString *)version;
```      

### Helpers
```objective-c
	  NSLog(@"%@", [SDVersion deviceVersionName:[SDVersion deviceVersion]]);
      /* e.g: Outputs 'Apple Watch 42mm' */

      NSLog(@"%@", [SDVersion deviceSizeName:[SDVersion deviceSize]]);
      /* e.g: Outputs '42mm' */
```

## tvOS

### Available methods
```objective-c
    + (DeviceVersion)deviceVersion;
	+ (NSString *)deviceName;
```
### Targetable models
	Apple TV (4th Generation)

    Simulator

### Available tvOS Version Finder methods
```objective-c
    + (BOOL)versionEqualTo:(NSString *)version;
    + (BOOL)versionGreaterThan:(NSString *)version;
    + (BOOL)versionGreaterThanOrEqualTo:(NSString *)version;
    + (BOOL)versionLessThan:(NSString *)version;
    + (BOOL)versionLessThanOrEqualTo:(NSString *)version;
```       

### Helpers
```objective-c
	  NSLog(@"%@", [SDVersion deviceVersionName:[SDVersion deviceVersion]]);
      /* e.g: Outputs 'Apple TV (4th Generation)' */
```

## Mac OS
```objective-c
      // Check for device model
      if ([SDVersion deviceVersion] == DeviceVersionIMac)
          NSLog(@"So you have a iMac? 💻");
      else if ([SDVersion deviceVersion] == DeviceVersionMacBookPro)
          NSLog(@"You're using a MacBook Pro.");

      // Check for screen size
      if ([SDVersion deviceSize] == Mac27Inch)
          NSLog(@"Whoah! You got a big ass 27 inch screen.");
      else if ([SDVersion deviceSize] == Mac21Dot5Inch)
          NSLog(@"You have a 21.5 inch screen.");

      // Check for screen resolution
      if ([SDVersion deviceScreenResolution] == DeviceScreenRetina)
          NSLog(@"Nice retina screen!");

      // Get screen resolution in pixels
      NSLog(@"%@", [SDVersion deviceScreenResolutionName:[SDVersion deviceScreenResolution]]);
      /* e.g: Outputs '{2880, 1800}' */

      // Check OSX Version (pass the minor version)
      if([SDVersion versionGreaterThanOrEqualTo:@"11"])
           NSLog(@"Looks like you are running OSX 10.11 El Capitan or 🆙.");
```

### Available methods
```objective-c
    + (DeviceVersion)deviceVersion;
    + (NSString *)deviceVersionString;
    + (DeviceSize)deviceSize;
    + (NSSize)deviceScreenResolutionPixelSize;
    + (DeviceScreenResolution)deviceScreenResolution;
```
### Targetable models
	DeviceVersionIMac
	DeviceVersionMacMini
	DeviceVersionMacPro
	DeviceVersionMacBook
	DeviceVersionMacBookAir
	DeviceVersionMacBookPro
	DeviceVersionXserve

### Targetable screen sizes
    Mac27Inch
	Mac24Inch
	Mac21Dot5Inch
	Mac20Inch
	Mac17Inch
	Mac15Inch
	Mac13Inch
	Mac12Inch
	Mac11Inch

### Targetable screen resolutions
    DeviceScreenRetina,
	DeviceScreenNoRetina

### Available OSX Version Finder methods
```objective-c
    + (BOOL)versionEqualTo:(NSString *)version;
    + (BOOL)versionGreaterThan:(NSString *)version;
    + (BOOL)versionGreaterThanOrEqualTo:(NSString *)version;
    + (BOOL)versionLessThan:(NSString *)version;
    + (BOOL)versionLessThanOrEqualTo:(NSString *)version;
    /* 'v' must be the minor OS Version. e.g: OSX 10.9 - 'v' is 9 */
```
### Helpers
```objective-c
      NSLog(@"%@", [SDVersion deviceSizeName:[SDVersion deviceSize]]);
      /* e.g: Outputs '15 inch' */

      NSLog(@"%@",[SDVersion deviceScreenResolutionName:[SDVersion deviceScreenResolution]])
      /* e.g: Outputs '{2880, 1800}' */
```

## Used by

<p align="center">
       <img src="https://dl.dropboxusercontent.com/s/yp3kwu2lobe9pvg/who-uses-sdversion.png?dl=0" alt="Who uses SDVersion">
</p>

## License
Usage is provided under the [MIT License](http://opensource.org/licenses/mit-license.php). See LICENSE for the full details.
