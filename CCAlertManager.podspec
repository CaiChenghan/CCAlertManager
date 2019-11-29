#
# Be sure to run `pod lib lint CCAlertManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CCAlertManager'
  s.version          = '1.0.0'
  s.summary          = 'iOS Alert Manager.'
  s.description      = <<-DESC
TODO: My iOS Alert Manager
                       DESC

  s.homepage         = 'https://github.com/CaiChenghan/CCAlertManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '1178752402@qq.com' => '蔡成汉' }
  s.source           = { :git => 'https://github.com/CaiChenghan/CCAlertManager.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'CCAlertManager/*.{h,m}'
end
