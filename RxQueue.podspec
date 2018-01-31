Pod::Spec.new do |s|
  s.name             = 'RxQueue'
  s.version          = '0.6.0'
  s.summary          = 'Simple queue using rxswift.'
  s.description      = <<-DESC
A simple queue that can handle items that define processing duration.
                       DESC
  s.homepage         = 'https://github.com/noppefoxwolf/RxQueue'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tomoya Hirano' => 'cromteria@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/RxQueue.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/noppefoxwolf'
  s.ios.deployment_target = '9.0'
  s.source_files = 'RxQueue/Classes/**/*'
  s.dependency 'RxSwift'
end
