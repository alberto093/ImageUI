Pod::Spec.new do |s|
  s.name             = 'ImageUI'
  s.version          = '0.1.0'
  s.summary          = 'A photo viewer inspired by Apple.'
  s.homepage         = 'https://github.com/alberto093/ImageUI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alberto Saltarelli' => 'a.saltarelli93@gmail.com' }
  s.source           = { :git => 'https://github.com/alberto093/ImageUI.git', :tag => s.version.to_s }
  s.social_media_url   = 'https://www.linkedin.com/in/alberto-saltarelli'
  s.ios.deployment_target = '11.0'
  s.source_files = 'ImageUI/**/*'
  s.dependency 'Nuke'
end
