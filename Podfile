platform :ios, '16.0'

target 'DarwiniumAirlines' do
  use_frameworks!

  # Darwinium iOS mobile SDK
  pod 'dwn_ios_sdk', :git => 'https://packages.darwinium.com/sdk/dwn_ios_sdk.git', :tag => '2.4.0'
end

# Pods ship with old minimum iOS versions that current Xcode rejects;
# align them with the app's deployment target.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
