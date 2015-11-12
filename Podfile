source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

xcodeproj 'WebDriverAgent.xcodeproj'

# UIAutomation Testing

target :WebDriverAgent, :exclusive => true do
  pod 'KissXML'
  pod 'RoutingHTTPServer'
end

target :WebDriverAgentLib, :exclusive => true do
  pod 'KissXML'
  pod 'RoutingHTTPServer'
end

target :WebDriverAgentLibTests, :exclusive => true do
  pod 'OCMock'
end


# XCT Testing

target :XCTWebDriverAgentLib, :exclusive => true do
  pod 'KissXML'
  pod 'RoutingHTTPServer'
end

target :XCTUITestRunner, :exclusive => true do
  pod 'KissXML'
  pod 'RoutingHTTPServer'
end