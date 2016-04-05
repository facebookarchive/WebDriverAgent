# WebDriverAgent

WebDriverAgent is a WebDriver server for iOS that runs inside the Simulator and is written entirely in Objective-C. It works by linking `XCTest.framework` and calling Apple's API to execute commands directly on device / simulator.
If you are looking for WebDriverAgent that uses `UIAutomation.framework` check [here](https://github.com/facebook/WebDriverAgent/tree/master/UIAWebDriverAgent)).

[![Build Status](https://travis-ci.org/facebook/WebDriverAgent.svg?branch=master)](https://travis-ci.org/facebook/WebDriverAgent)

## Building

Our dependencies are tracked with Carthage. First run

``
carthage bootstrap
``

and then open `WebDriverAgent.xcodeproj`.

## Running

To play around with WebDriverAgent you can simply start WebDriverAgentRunner tests via Xcode or xcodebuild:
```
xcodebuild -workspace WebDriverAgent.xcworkspace -scheme WebDriverAgentRunner -destination id='<DEVICE_UDID>' test
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

## Contributing

See the CONTRIBUTING file for how to help out.

## License

WebDriverAgent is BSD-licensed. We also provide an additional patent grant.
