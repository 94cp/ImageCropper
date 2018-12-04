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
/// - success: 成功，返回类型：[(image: T, frame: CGRect)] （frame是裁剪图片在原图的位置尺寸）
/// - notFound: 没找到需要识别的类型图像
/// - failure: 失败
public enum ImageCropResult<T> {
    case success([(image: T, frame: CGRect)])
    case notFound(image: T, frame: CGRect)
    case failure(image: T, frame: CGRect, error: Error)
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
    ///   - padding: 裁剪扩展内边距，默认：zero
    ///   - completion: 结果回调
    func crop(type: DetectionType, padding: UIEdgeInsets = .zero, completion: @escaping (ImageCropResult<CGImage>) -> Void) {
        if #available(iOS 11.0, *) {
            visionCrop(type: type, padding: padding, completion: completion)
        } else {
            coreImageCrop(type: type, padding: padding, completion: completion)
        }
    }
    
    @available(iOS 11.0, *)
    private func visionCrop(type: DetectionType, padding: UIEdgeInsets, completion: @escaping (ImageCropResult<CGImage>) -> Void) {
        // 设置回调
        let completionHandle: VNRequestCompletionHandler = { request, error in
            guard error == nil else {
                completion(.failure(image: self.detectable, frame: CGRect(x: 0, y: 0, width: self.detectable.width, height: self.detectable.height), error: error!))
                return
            }
            
            let cropImageResults = request.results?.map({ result -> (image: CGImage, frame: CGRect)? in
                guard let detectedObj = result as? VNDetectedObjectObservation else { return nil }
                let cropImageResult = self.cropImage(object: detectedObj, padding: padding)
                return cropImageResult
            }).compactMap { $0 }
            
            guard let result = cropImageResults, result.count > 0 else {
                completion(.notFound(image: self.detectable, frame: CGRect(x: 0, y: 0, width: self.detectable.width, height: self.detectable.height)))
                return
            }
            
            completion(.success(result))
        }
        
        // 创建识别请求
        let req = createVNImageRequest(type: type, completionHandle: completionHandle)
        
        do {
            try VNImageRequestHandler(cgImage: detectable, options: [:]).perform([req])
        } catch let error {
            completion(.failure(image: detectable, frame: CGRect(x: 0, y: 0, width: self.detectable.width, height: self.detectable.height), error: error))
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
    
    private func coreImageCrop(type: DetectionType, padding: UIEdgeInsets, completion: @escaping (ImageCropResult<CGImage>) -> Void) {
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
        
        let cropImageResults = results?.map({ (result) -> (image: CGImage, frame: CGRect)? in
            let cropImageResult = self.cropImage(detectedBounds: result.bounds.applying(transform), ciImageSize: ciImageSize, padding: padding)
            return cropImageResult
        }).compactMap { $0 }
        
        guard let result = cropImageResults, result.count > 0 else {
            completion(.notFound(image: detectable, frame: CGRect(x: 0, y: 0, width: self.detectable.width, height: self.detectable.height)))
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
    private func cropImage(object: VNDetectedObjectObservation, padding: UIEdgeInsets) -> (image: CGImage, frame: CGRect)? {
        let width = object.boundingBox.width * CGFloat(detectable.width)
        let height = object.boundingBox.height * CGFloat(detectable.height)
        let x = object.boundingBox.origin.x * CGFloat(detectable.width)
        let y = (1 - object.boundingBox.origin.y) * CGFloat(detectable.height) - height
        
        let croppingRect = CGRect(x: x - padding.left, y: y - padding.top, width: width + (padding.left + padding.right), height: height + (padding.top + padding.bottom))
        
        guard let image = self.detectable.cropping(to: croppingRect) else { return nil }
        
        return (image: image, frame: croppingRect)
    }
    
    /// CoreImage 图片裁剪方法
    private func cropImage(detectedBounds: CGRect, ciImageSize: CGSize, padding: UIEdgeInsets) -> (image: CGImage, frame: CGRect)? {
        var croppingRect = detectedBounds
        
        let scaleX = CGFloat(detectable.width) / ciImageSize.width
        let scaleY = CGFloat(detectable.height) / ciImageSize.height
        let offsetX = (CGFloat(detectable.width) - ciImageSize.width * scaleX) * 0.5
        let offsetY = (CGFloat(detectable.height) - ciImageSize.height * scaleY) * 0.5

        croppingRect = croppingRect.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        croppingRect.origin.x += offsetX - padding.left
        croppingRect.origin.y += offsetY - padding.top
        croppingRect.size.width += (padding.left + padding.right)
        croppingRect.size.height += (padding.top + padding.bottom)

        guard let image = self.detectable.cropping(to: croppingRect) else { return nil }
        
        return (image: image, frame: croppingRect)
    }
}

// MARK: - 🔥UIImage 裁剪🔥
public extension ImageCropper where T: UIImage {
    
    /// 裁剪出UIImage图片方法
    ///
    /// - Parameters:
    ///   - type: 裁剪类型
    ///   - padding: 裁剪扩展内边距，默认：zero
    ///   - completion: 结果回调
    func crop(type: DetectionType, padding: UIEdgeInsets = .zero, completion: @escaping (ImageCropResult<UIImage>) -> Void) {
        detectable.cgImage!.detector.crop(type: type, padding: padding) { result in
            switch result {
            case .success(let cropImageResults):
                let results = cropImageResults.map { return (image: UIImage(cgImage: $0.image), frame: $0.frame) }
                completion(.success(results))
            case .notFound(_, let frame):
                completion(.notFound(image: self.detectable, frame: frame))
            case .failure(_, let frame, let error):
                completion(.failure(image: self.detectable, frame: frame, error: error))
            }
        }
    }
}
