Pod::Spec.new do |s|
  s.name             = 'ImageUI'
  s.version          = '0.4.0'
  s.summary          = 'A photo viewer inspired by Apple Photos app.'
  s.homepage         = 'https://github.com/alberto093/ImageUI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alberto Saltarelli' => 'a.saltarelli93@gmail.com' }
  s.source           = { :git => 'https://github.com/alberto093/ImageUI.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_versions = ['5.1', '5.2']
  s.source_files = 'Sources/ImageUI/**/*.swift'
  s.dependency 'Nuke'
end
