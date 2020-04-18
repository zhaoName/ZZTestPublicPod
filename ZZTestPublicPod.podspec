#
# Be sure to run `pod lib lint ZZTestPublicPod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZZTestPublicPod'
  s.version          = '0.0.4'
  s.summary          = 'ZZTestPublicPod.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  test pubilc pods
                       DESC

  s.homepage         = 'https://github.com/zhaoName/ZZTestPublicPod'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhaoName' => 'zhao1529835@126.com' }
  s.source           = { :git => 'https://github.com/zhaoName/ZZTestPublicPod.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.static_framework = true
  s.ios.deployment_target = '9.0'

#  s.source_files = 'ZZTestPublicPod/Classes/**/*'
  s.ios.vendored_frameworks = 'ZZTestPublicPod.framework'
  # s.requires_arc = false
  # s.requires_arc = 'ZZTestPublicPod/Classes/arc/*'
  # s.resource_bundles = {
  #   'ZZTestPublicPod' => ['ZZTestPublicPod/Assets/*.png']
  # }

#  s.public_header_files = 'Pod/Classes/**/**/*.h'
#  s.private_header_files = 'Pod/Classes/**/**/*.m'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
