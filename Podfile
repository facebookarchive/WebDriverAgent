source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

xcodeproj 'WebDriverAgent.xcodeproj'

pod 'KissXML'
pod 'RoutingHTTPServer'

target :WebDriverAgentLib, :exclusive => true do
  pod 'KissXML'
  pod 'RoutingHTTPServer'
end

target :WebDriverAgentLibTests, :exclusive => true do
  pod 'OCMock'
end
