# WebDriverAgent [![GitHub license](https://img.shields.io/badge/license-BSD-lightgrey.svg)](LICENSE) [![Build Status](https://travis-ci.org/facebook/WebDriverAgent.svg?branch=master)](https://travis-ci.org/facebook/WebDriverAgent) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

WebDriverAgent is a WebDriver server for iOS that runs inside the Simulator and is written entirely in Objective-C. It works by linking `XCTest.framework` and calling Apple's API to execute commands directly on device / simulator.
If you are looking for WebDriverAgent that uses `UIAutomation.framework` check [here](https://github.com/facebook/WebDriverAgent/tree/master/UIAWebDriverAgent)).

## Building

Our dependencies are tracked with Carthage. First run

``
carthage bootstrap --platform ios
``

and then open `WebDriverAgent.xcodeproj`.

## Running

Enable developer mode:

```
$ DevToolsSecurity --enable
Developer mode is now enabled.
```

If developer mode isn't enabled then you'll see this message:
> DTServiceHub: Instruments wants permission to analyze other processes. Please enter an administrator username and password to allow this.
> Failed to authorize rights (0x1) with status: -60007.

To play around with WebDriverAgent you can simply start WebDriverAgentRunner tests via Xcode or xcodebuild:
```
xcodebuild -project WebDriverAgent.xcodeproj -scheme WebDriverAgentRunner -destination 'platform=iOS Simulator,name=iPhone 6' test
```

When simulator/device launches it should be ready for receiving requests. To get ip address under with device is available you can check device logs for line "ServerURLHere->[DEVICE_URL]<-ServerURLHere"

Use curl to start testing the app:
```
curl -X POST -H "Content-Type: application/json" -d "{\"desiredCapabilities\":{\"bundleId\":\"$BUNDLE_ID\", \"app\":\"/path/to/app/on/local/machine/magicapp.app\"}}" http://[DEVICE_URL]/session/
```

After application launches you can inspect it by opening web browser on [/inspector](https://localhost:8100/inspector) endpoint
or query elements with curl request:
```
curl -X POST -H "Content-Type: application/json" -d "{"using":"xpath","value":"//XCUIElementTypeButton"}" http://[DEVICE_URL]/session/[SESSION_ID]/elements
```

Have fun!

## For Contributors

Please make sure you’ve followed the guidelines in [CONTRIBUTING](CONTRIBUTING.md), if you want to help out.

## License

[`WebDriverAgent` is BSD-licensed](LICENSE). We also provide an additional [patent grant](PATENTS).
