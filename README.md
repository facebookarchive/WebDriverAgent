# WebDriverAgent [![GitHub license](https://img.shields.io/badge/license-BSD-lightgrey.svg)](LICENSE) [![Build Status](https://travis-ci.org/facebook/WebDriverAgent.svg?branch=master)](https://travis-ci.org/facebook/WebDriverAgent) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

WebDriverAgent is a [WebDriver server](https://w3c.github.io/webdriver/webdriver-spec.html) implementation for iOS that can be used to remote control iOS devices. It allows you to launch & kill applications, tap & scroll views or confirm view presence on a screen. This makes it a perfect tool for application end-to-end testing or general purpose device automation. It works by linking `XCTest.framework` and calling Apple's API to execute commands directly on a device. WebDriverAgent is developed and used at Facebook for end-to-end testing and is successfully adopted by [Appium](http://appium.io).

## Features
 * Works with device & simulator
 * Implements most of [WebDriver Spec](https://w3c.github.io/webdriver/webdriver-spec.html)
 * Implements part of [Mobile JSON Wire Protocol Spec](https://github.com/SeleniumHQ/mobile-spec/blob/master/spec-draft.md)
 * [USB support](https://github.com/facebook/WebDriverAgent/wiki/USB-support) for devices
 * Inspector [endpoint](http://localhost:8100/inspector) with friendly user interface to inspect current device state
 * Easy development cycle as it can be launched & debugged directly via Xcode
 * Unsupported yet, but works with tvOS & OSX

[![Demo Video](https://j.gifs.com/gJymG9.gif)](https://youtu.be/EatiYGFxBxY)

## Getting Started
To get the project set up just run bootstrap script:
```
./Scripts/bootstrap.sh
```
It will:
* fetch all dependencies with [Carthage](https://github.com/Carthage/Carthage)
* build Inspector bundle using [npm](https://www.npmjs.com)

After it is finished you can simply open `WebDriverAgent.xcworkspace` and start `WebDriverAgentRunner testRunnerSocket` 
and start sending [requests](https://github.com/facebook/WebDriverAgent/wiki/Queries).

For building client manually :
```
sh ./Scripts/build-socket.sh
```

Start Node Server :
```
sh ./Scripts/start-server.sh
```

Open "http://localhost:8000" : You will see the connected devices. If there is no devices, run the `WebDriverAgentRunner testRunnerSocket`.


## Running from terminal :

Check all available Device :
```
 instruments -s devices
```

Run the below command to start simulator :

```
xcodebuild test -workspace WebDriverAgent.xcworkspace -scheme WebDriverAgentRunner -destination "platform=iOS Simulator,OS=11.2,name=iPhone 8 Plus"
```
update `-destination` for devices as available in your system.

For running in Real device, You need to provide the device id :

```
xcodebuild test -workspace WebDriverAgent.xcworkspace -scheme WebDriverAgentRunner -destination "platform=iOS,id=8c9406453401735ad174d8f4118e2347772fc969"
```
NOTE: 
Before running in device Go to the SocketIO project, put `BITCODE_GENERATION_MODE` as `marker` and `ENABLE_BITCODE` as `NO`

## Run failure

In case the program builds but there is the following run error
Testing failed:
Linker command failed with exit code 1 (use -v to see invocation)
** TEST FAILED **

The following build commands failed:
Ld /Users/USER_NAME/Library/Developer/Xcode/DerivedData/WebDriverAgent-ajlpezvrbmujhvcgzjblwcnckdvv/Build/Products/Debug-iphoneos/SocketIO.framework/SocketIO normal arm64

Go to the SocketIO project, put `BITCODE_GENERATION_MODE` as `marker` and `ENABLE_BITCODE` as `NO`


More about how to start WebDriverAgent [here](https://github.com/facebook/WebDriverAgent/wiki/Starting-WebDriverAgent).

## Known Issues
If you are having some issues please checkout [wiki](https://github.com/facebook/WebDriverAgent/wiki/Common-Issues) first.

## For Contributors
If you want to help us out, you are more than welcome to. However please make sure you have followed the guidelines in [CONTRIBUTING](CONTRIBUTING.md).

## License

[`WebDriverAgent` is BSD-licensed](LICENSE). We also provide an additional [patent grant](PATENTS).

Have fun!
