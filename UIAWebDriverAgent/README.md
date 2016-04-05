
# WebDriverAgent [![Build Status](https://travis-ci.org/facebook/WebDriverAgent.svg?branch=master)](https://travis-ci.org/facebook/WebDriverAgent)

WebDriverAgent is a WebDriver server for iOS that runs inside the Simulator and is written entirely in Objective-C. WebDriverAgent works under-the-hood by linking to `UIAutomation.framework` and calling the same APIs that are exposed through Apple's UIAutomation.js framework. Because it is not tied to an Instruments run, it is able to run across applications or even on the home screen. Furthermore, it's much faster than any JavaScript UIAutomation.js driver as it runs a native HTTP server and does not need to ferry commands and results through a makeshift run loop.

## Building

Our dependencies are tracked with Carthage. First run

``
carthage bootstrap
``

and then open `WebDriverAgent.xcodeproj`.

## Running WebDriverAgent

To add new commands or just fool around with WebDriverAgent, you can run it from within Xcode. Because WebDriverAgent is a daemon, you will not notice any UI when it runs. Hit [the /tree endpoint](http://localhost:8100/tree) to confirm it's running.

In practice, you would want to start it up alongside your application. You can use Apple's `simctl` tool for this or [FBSimulatorControl](https://github.com/facebook/FBSimulatorControl). This is how you might do it with `simctl`:

```
# 1. Open the Simulator and application you wish to test.

# 2. Start WebDriverAgent.
xcrun simctl spawn booted <WebDriverAgent_path>
# e.g. xcrun simctl spawn booted /Users/mehdi/src/WebDriverAgent/Build/Products/Debug-iphonesimulator/WebDriverAgent.app/WebDriverAgent
```

When simulator/device launches with blue screen it should be ready for receiving requests. To get ip address under with device is available you can check device logs for line "ServerURLHere->[DEVICE_URL]<-ServerURLHere"

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

Have fun!

## Contributing

See the CONTRIBUTING file for how to help out.

## License

WebDriverAgent is BSD-licensed. We also provide an additional patent grant.
