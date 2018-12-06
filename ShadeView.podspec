Pod::Spec.new do |s|
  s.name             = 'ShadeView'
  s.version          = '0.1.17'
  s.summary          = 'Simple swipe up view'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/super-ultra/ShadeView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ilya Lobanov' => 'owlefy@gmail.com' }
  s.source           = { :git => 'https://github.com/super-ultra/ShadeView.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.swift_version = '4.2'
  s.source_files = 'Sources/**/*'
  s.frameworks = 'UIKit'
  s.dependency 'pop', '~> 1.0'
end
