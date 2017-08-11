Pod::Spec.new do |s|
  s.name         = 'GBFeatureManager'
  s.version      = '1.0.0'
  s.summary      = 'Simple iOS and Mac OS X feature manager for unlocking functionality (e.g. for IAP purchases).'
  s.homepage     = 'https://github.com/lmirosevic/GBFeatureManager'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Luka Mirosevic' => 'luka@goonbee.com' }
  s.platform     = :ios, '5.0'
  s.source       = { git: 'https://github.com/lmirosevic/GBFeatureManager.git', tag: s.version.to_s }
  s.source_files  = 'GBFeatureManager/GBFeatureManager.{h,m}'
  s.public_header_files = 'GBFeatureManager/GBFeatureManager.h'
  s.requires_arc = true

  s.dependency 'GBToolbox', '>= 22.4'
  s.dependency 'GBStorage', '~> 2.1'
end
