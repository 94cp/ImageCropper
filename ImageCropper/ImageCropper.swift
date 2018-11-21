//
//  ImageCropper.swift
//  ImageCropper
//
//  Created by chen p on 2018/11/21.
//  Copyright © 2018 chenp. All rights reserved.
//

import UIKit
#if canImport(Vision)
    import Vision
#else
    import CoreImage
#endif

extension NSObject: ImageCroppable {}
extension CGImage: ImageCroppable {}

/// 图片裁剪协议
public protocol ImageCroppable {}

/// 裁剪类型
///
/// - face: 人脸
/// - barcode: 条形码、二维码等
/// - text: 文本
/// - rectangle: 矩形
public enum DetectionType {
    case face
    case barcode
    case text
    case rectangle
}

/// 识别结果
///
/// - success: 成功
/// - notFound: 没找到需要识别的类型图像
/// - failure: 失败
public enum ImageDetectResult<T> {
    case success([T])
    case notFound
    case failure(Error)
}

/// 图像裁剪工具类
public struct ImageCropper<T> {
    let detectable: T
    init(_ detectable: T) {
        self.detectable = detectable
    }
}

public extension ImageCroppable {
    var detector: ImageCropper<Self> {
        return ImageCropper(self)
    }
}

// MARK: - 🔥CGImage 裁剪🔥
public extension ImageCropper where T: CGImage {
    
    /// 裁剪出CGImage图片方法
    ///
    /// - Parameters:
    ///   - type: 裁剪类型
    ///   - completion: 结果回调
    func crop(type: DetectionType, completion: @escaping (ImageDetectResult<CGImage>) -> Void) {
        if #available(iOS 11.0, *) {
            visionCrop(type: type, completion: completion)
        } else {
            coreImageCrop(type: type, completion: completion)
        }
    }
    
    @available(iOS 11.0, *)
    private func visionCrop(type: DetectionType, completion: @escaping (ImageDetectResult<CGImage>) -> Void) {
        // 设置回调
        let completionHandle: VNRequestCompletionHandler = { request, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            let cropImages = request.results?.map({ result -> CGImage? in
                guard let detectedObj = result as? VNDetectedObjectObservation else { return nil }
                let image = self.cropImage(object: detectedObj)
                return image
            }).compactMap { $0 }
            
            guard let result = cropImages, result.count > 0 else {
                completion(.notFound)
                return
            }
            
            completion(.success(result))
        }
        
        // 创建识别请求
        let req = createVNImageRequest(type: type, completionHandle: completionHandle)
        
        do {
            try VNImageRequestHandler(cgImage: detectable, options: [:]).perform([req])
        } catch let error {
            completion(.failure(error))
        }
    }
    
    @available(iOS 11.0, *)
    private func createVNImageRequest(type: DetectionType, completionHandle: @escaping VNRequestCompletionHandler) -> VNImageBasedRequest {
        switch type {
        case .face:
            return VNDetectFaceRectanglesRequest(completionHandler: completionHandle)
        case .barcode:
            return VNDetectBarcodesRequest(completionHandler: completionHandle)
        case .text:
            return VNDetectTextRectanglesRequest(completionHandler: completionHandle)
        case .rectangle:
            return VNDetectRectanglesRequest(completionHandler: completionHandle)
        }
    }
    
    private func coreImageCrop(type: DetectionType, completion: @escaping (ImageDetectResult<CGImage>) -> Void) {
        let ciImage = CIImage(cgImage: detectable)
        // 识别结果精度
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        // 设置识别类型
        let detector = CIDetector(ofType: getDetectorType(type: type), context: nil, options: accuracy)
        // 识别结果
        let results = detector?.features(in: ciImage)
        
        let ciImageSize = ciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        let cropImages = results?.map({ (result) -> CGImage? in
            guard let detectedObj = result as? CIFaceFeature else { return nil }
            let image = self.cropImage(bounds: detectedObj.bounds.applying(transform), ciImageSize: ciImageSize)
            return image
        }).compactMap { $0 }
        
        guard let result = cropImages, result.count > 0 else {
            completion(.notFound)
            return
        }
        
        completion(.success(result))
    }
    
    private func getDetectorType(type: DetectionType) -> String {
        switch type {
        case .face:
            return CIDetectorTypeFace
        case .barcode:
            return CIDetectorTypeQRCode
        case .text:
            return CIDetectorTypeText
        case .rectangle:
            return CIDetectorTypeRectangle
        }
    }
    
    /// Vision 图片裁剪方法
    @available(iOS 11.0, *)
    private func cropImage(object: VNDetectedObjectObservation) -> CGImage? {
        let width = object.boundingBox.width * CGFloat(detectable.width)
        let height = object.boundingBox.height * CGFloat(detectable.height)
        let x = object.boundingBox.origin.x * CGFloat(detectable.width)
        let y = (1 - object.boundingBox.origin.y) * CGFloat(detectable.height) - height
        
        let croppingRect = CGRect(x: x, y: y, width: width, height: height)
        
        let image = self.detectable.cropping(to: croppingRect)
        return image
    }
    
    /// CoreImage 图片裁剪方法
    private func cropImage(bounds: CGRect, ciImageSize: CGSize) -> CGImage? {
        var croppingRect = bounds
        
        let scaleX = CGFloat(detectable.width) / ciImageSize.width
        let scaleY = CGFloat(detectable.height) / ciImageSize.height
        let offsetX = (CGFloat(detectable.width) - ciImageSize.width * scaleX) / 2
        let offsetY = (CGFloat(detectable.height) - ciImageSize.height * scaleY) / 2

        croppingRect = croppingRect.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        croppingRect.origin.x += offsetX
        croppingRect.origin.y += offsetY

        let image = self.detectable.cropping(to: croppingRect)
        return image
    }
}

// MARK: - 🔥UIImage 裁剪🔥
public extension ImageCropper where T: UIImage {
    
    /// 裁剪出UIImage图片方法
    ///
    /// - Parameters:
    ///   - type: 裁剪类型
    ///   - completion: 结果回调
    func crop(type: DetectionType, completion: @escaping (ImageDetectResult<UIImage>) -> Void) {
        detectable.cgImage!.detector.crop(type: type) { result in
            switch result {
            case .success(let cgImages):
                let faces = cgImages.map { cgImage -> UIImage in
                    return UIImage(cgImage: cgImage)
                }
                completion(.success(faces))
            case .notFound:
                completion(.notFound)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
