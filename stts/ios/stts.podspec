#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint stts.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stts'
  s.version          = '1.0.0'
  s.summary          = 'Speech-to-Text Flutter plugin.'
  s.description      = <<-DESC
Speech-to-Text Flutter plugin.
                       DESC
  s.homepage         = 'http://github.com/llfbanfit/stts'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'stts/Sources/stts/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy manifest
  s.resource_bundles = {'stts_ios_privacy' => ['stts/Sources/stts/PrivacyInfo.xcprivacy']}
end
