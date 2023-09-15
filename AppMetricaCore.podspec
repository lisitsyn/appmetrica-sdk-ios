Pod::Spec.new do |s|
  s.name = "AppMetricaCore"
  s.version = '5.0.0'
  s.summary = "Powerful and flexible module offering a wide range of tracking and analytics tools for your application"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.frameworks = 'UIKit', 'Foundation', 'CoreLocation', 'CoreGraphics', 'SystemConfiguration'
  s.libraries   = 'z', 'sqlite3', 'c++'

  s.dependency 'AppMetricaLog', '~> 5.0'
  s.dependency 'AppMetricaNetwork', '~> 5.0'
  s.dependency 'AppMetricaCoreUtils', '~> 5.0'
  s.dependency 'AppMetricaHostState', '~> 5.0'
  s.dependency 'AppMetricaProtobufUtils', '~> 5.0'
  s.dependency 'AppMetricaPlatform', '~> 5.0'
  s.dependency 'AppMetricaStorageUtils', '~> 5.0'
  s.dependency 'AppMetricaEncodingUtils', '~> 5.0'

  s.dependency 'FMDB', '= 2.7.5'
  s.dependency 'protobuf-c', '= 1.2.1'
  
  s.header_dir = s.name
  s.source_files = [
      "#{s.name}/Sources/**/*.{h,m,c}",
      'AppMetricaCoreExtension/Sources/include/**/*.h',
  ]
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.compiler_flags = '-Wshadow-ivar', '-Werror', '-Wbool-conversion',
  '-Wconstant-conversion', '-Wdeprecated-objc-isa-usage',
  '-Werror=incompatible-pointer-types',
  '-Wreturn-type', '-Wswitch', '-Wparentheses', '-Wsign-compare',
  '-Wuninitialized', '-Wunused-function', '-Wunused-label', '-Wunused-value',
  '-Wunused-variable', '-Wconversion', '-Wenum-conversion', '-Wint-conversion',
  '-Wdocumentation'

end