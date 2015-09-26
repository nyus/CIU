source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '7.0'

xcodeproj 'DaDa.xcodeproj'

target 'DaDa' do
    pod 'Masonry', '~> 0.6'
    pod 'GoogleAnalytics-iOS-SDK'
    pod 'Parse', '~> 1.8.5'
    pod 'ParseFacebookUtilsV4', '~> 1.8'
    pod 'FBSDKCoreKit', '~> 4.0'
    pod 'FBSDKLoginKit', '~> 4.0'
    
    pod 'CrittercismSDK', '~> 5.2'
    pod 'FlurrySDK', '~> 6.5'
    pod 'SVPullToRefresh'
    pod 'ELCImagePickerController', '~> 0.2'
    pod 'TSMessages', :git => 'https://github.com/nyus2014/TSMessages.git', :branch => 'huang'
end

target 'DaDa Tests', :exclusive => true do
    pod 'KIF', '~> 3.0', :configurations => ['Debug']
end