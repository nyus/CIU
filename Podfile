source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '7.0'

xcodeproj 'DaDa.xcodeproj'

target 'DaDa' do
  pod 'Masonry', '~> 0.6'
  pod 'GoogleAnalytics-iOS-SDK'
  pod 'Facebook-iOS-SDK', '~> 3.23'
  pod 'ParseFacebookUtils', '~> 1.7'
  pod 'CrittercismSDK', '~> 5.2'
  pod 'FlurrySDK', '~> 6.5'
  pod 'SVPullToRefresh', '~> 0.4'
  pod 'ELCImagePickerController', '~> 0.2'
  pod 'TSMessages', :git => 'https://github.com/nyus2014/TSMessages.git', :branch => 'huang'
end

target 'DaDa Tests', :exclusive => true do
    pod 'KIF', '~> 3.0', :configurations => ['Debug']
end