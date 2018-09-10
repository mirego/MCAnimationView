Pod::Spec.new do |s|
  s.name     = 'MCAnimationView'
  s.version  = '1.1.0'
  s.summary  = 'UIImageView alternative for animations that does not load all the images in memory at once and provide a callback when animation is done.'
  s.homepage = 'https://github.com/mirego/MCAnimationView'
  s.license  = 'BSD 3-Clause'
  s.authors  = { 'Mirego, Inc.' => 'info@mirego.com' }
  s.source   = { :git => 'https://github.com/mirego/MCAnimationView.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Mirego'

  s.ios.deployment_target = '7.0'

  s.dependency 'MCUIImageAdvanced'

  s.requires_arc = true
  s.source_files = 'MCAnimationView/Classes/*.{h,m}'
end
