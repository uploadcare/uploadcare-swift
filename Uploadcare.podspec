Pod::Spec.new do |s|
  s.name             = 'Uploadcare'
  s.version          = '0.14.0'
  s.summary          = 'Swift integration for Uploadcare'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Swift API client for iOS, iPadOS, tvOS, macOS, and watchOS handles uploads and
  further operations with files by wrapping Uploadcare Upload and REST APIs.
                       DESC

  s.homepage         = 'https://github.com/uploadcare/uploadcare-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Uploadcare, Inc' => 'hello@uploadcare.com' }
  s.source           = { :git => 'https://github.com/uploadcare/uploadcare-swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/uploadcare'

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '11.0'
  s.watchos.deployment_target = '5.0'

  s.swift_versions = ['5.6', '5.7', '5.8', '5.9', '5.10']

  s.source_files = 'Sources/Uploadcare/**/*'
  
  # s.resource_bundles = {
  #   'TestLibPod' => ['TestLibPod/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
