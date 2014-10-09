Pod::Spec.new do |s|
  s.name     = 'SIActionSheet'
  s.version  = '1.1'
  s.platform = :ios
  s.license  = 'MIT'
  s.summary  = 'An UIActionSheet replacement.'
  s.homepage = 'https://github.com/Sumi-Interactive/SIActionSheet'
  s.author   = { 'Sumi Interactive' => 'developer@sumi-sumi.com' }
  s.source   = { :git => 'https://github.com/Sumi-Interactive/SIActionSheet.git',
                 :tag => '1.1' }

  s.description = 'An SIActionSheet replacement with block syntax.'

  s.requires_arc = true
  s.framework    = 'QuartzCore'
  s.source_files = 'SIActionSheet/*.{h,m}'
  s.dependency 'SISecondaryWindowRootViewController', '~> 0.1'

end
