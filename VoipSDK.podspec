#
#  Be sure to run `pod spec lint VoipSDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "VoipSDK"
  s.version      = "0.0.1"
  s.summary      = "pjsip voip"
  s.description  = <<-DESC
                   TODO:Add long description of the pod here.
                   DESC

  s.homepage     = "http://git.dev.sh.ctripcorp.com/wanglili/iOSVoipFramework"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author       = { "wll王黎黎" => "wanglili@ctrip.com" }
  s.platform     = :ios, "7.0"

  s.source       = { :git => "git@git.dev.sh.ctripcorp.com:wanglili/iOSVoipFramework.git", :branch => "master" }

  s.source_files  =  "VoipSDK/**/*.{h,m,mm,hpp,cpp,c}","VoipSDK/*.{h,m}"
  s.public_header_files = "VoipSDK/VoipSDK.h"

  s.resources = ["VoipSDK/icons/*.png","VoipSDK/*.{storyboard}","VoipSDK/*.xib"]

  s.frameworks = "CoreTelephony", "CFNetwork","AVFoundation","AudioToolbox","UIKit","Foundation"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"

  s.xcconfig = { 'ENABLE_BITCODE' => 'NO'}
  # s.dependency "JSONKit", "~> 1.4"

end
