#
#  Be sure to run `pod spec lint ImageCropper.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = "ImageCropperKit"
  s.version          = "1.1.2"
  s.summary          = "Detect and crop faces, barcodes, texts or rectangle in your image.（图片裁剪：支持人脸、二维码/条形码、文本、方框）"
  s.homepage         = "https://github.com/cp110/ImageCropper"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "cp110" => "1107223894@qq.com" }
  s.source           = { :git => "https://github.com/cp110/ImageCropper.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "10.0"

  s.source_files = 'ImageCropper/*.swift'
  
  s.requires_arc = true
  s.swift_version = '4.2'
end
