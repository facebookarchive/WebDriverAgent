# WebDriverAgent

WebDriverAgent is a WebDriver server for iOS that runs inside the Simulator and is written entirely in Objective-C. 

[![Build Status](https://travis-ci.org/facebook/WebDriverAgent.svg?branch=master)](https://travis-ci.org/facebook/WebDriverAgent)

## Building

Our dependencies are tracked with CocoaPods. First run

``
pod install
``

and then open `WebDriverAgent.xcworkspace`.

## Running

To add new commands or just fool around with WebDriverAgent, you can run it from within Xcode. Because WebDriverAgent is a daemon, you will not notice any UI when it runs. Hit [the /tree endpoint](http://localhost:8100/tree) to confirm it's running.

In practice, you would want to start it up alongside your application. You can use Apple's `simctl` tool for this or [FBSimulatorControl](https://github.com/facebook/FBSimulatorControl). This is how you might do it with `simctl`:

```
# 1. Open the Simulator and application you wish to test.

# 2. Start WebDriverAgent.
xcrun simctl spawn booted <WebDriverAgent_path>
# e.g. xcrun simctl spawn booted /Users/mehdi/src/WebDriverAgent/Build/Products/Debug-iphonesimulator/WebDriverAgent.app/WebDriverAgent
```

## How it works

WebDriverAgent works under-the-hood by linking to `UIAutomation.framework` and calling the same APIs that are exposed through Apple's UIAutomation.js framework.

Because it is not tied to an Instruments run, it is able to run across applications or even on the home screen. Furthermore, it's much faster than any JavaScript UIAutomation.js driver as it runs a native HTTP server and does not need to ferry commands and results through a makeshift run loop.

## Contributing

See the CONTRIBUTING file for how to help out.

## License

WebDriverAgent is BSD-licensed. We also provide an additional patent grant.
