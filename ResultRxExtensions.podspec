Pod::Spec.new do |s|
  s.name         = "ResultRxExtensions"
  s.version      = "0.1.0"
  s.summary      = "ResultRxExtensions provides a more convenient way of using Result in RxSwift"

  s.homepage     = "https://github.com/sergeysmagleev/ResultRxExtensions"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Sergey Smagleev" => "sergey@door2door.io" }
  s.social_media_url   = "https://twitter.com/sergeysmagleev"
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/sergeysmagleev/ResultRxExtensions.git", :tag => "#{s.version}" }
  s.source_files  = "Source/**/*.{swift}"
  s.requires_arc = true
  s.dependency 'RxSwift', '~> 4.0'
  s.dependency 'Result', '~> 3.0.0'
end
