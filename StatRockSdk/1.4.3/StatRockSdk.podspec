#
# Be sure to run `pod lib lint StatRockSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'StatRockSdk'
  s.version          = '1.4.3'
  s.summary          = 'The StatRock SDK.'
  s.description      = 'The SDK allows to integrate video ads into native IOS applications.'

  s.homepage         = 'https://github.com/stat-rock/ios-sdk'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'dev@stat-rock.com' => 'dev@stat-rock.com' }
  s.source           = { :git => 'https://github.com/stat-rock/ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'
  s.source_files = 'StatRockSdk/Classes/**/*'
end
