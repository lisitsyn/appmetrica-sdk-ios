Pod::Spec.new do |s|
  s.name = "AppMetricaAnalytics"
  s.version = '5.0.0'
  s.summary = "AppMetrica Analytics"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.default_subspec = 'Analytics'
  
  s.subspec "Analytics" do |analytics|
    analytics.dependency 'AppMetricaCore', '~> 5.0'
    analytics.dependency 'AppMetricaAdSupport', '~> 5.0'
    analytics.dependency 'AppMetricaWebKit', '~> 5.0'
  end
  
  s.subspec "NoAdSupport" do |noAdSupport|
    noAdSupport.dependency 'AppMetricaCore', '~> 5.0'
    noAdSupport.dependency 'AppMetricaWebKit', '~> 5.0'
  end
end