# ImageCropper

ImageCropper is a library developed on Swift. With ImageCropper you can easily detect and crop faces, texts, barcodes or rectangles in your image with iOS 11 Vision (iOS 10 Core Image) api. It will automatically create new images containing each object found within a given image.

ImageCropper是纯swift编写的库。使用它可以容易地将给定图片中的 人脸、文本、二维码/条形码 或者 方框 裁剪出来（对于iOS 11使用Vision库，iOS 10使用Core Image）。

## Features

- [x] Crop image
- [x] Detect face, text, barcode or rectangle

## Example

| Normal Crop | Padding Crop |
| :-: | :-: |
| <a href="url"><img src="https://github.com/cp110/ImageCropper/blob/master/Screenshots/normal_crop.png" align="top" height="406" width="187.5" ></a> | <a href="url"><img src="https://github.com/cp110/ImageCropper/blob/master/Screenshots/padding_crop.png" align="top" height="406" width="187.5" ></a> |

## Requirements
- iOS 10.0+
- Swift 4.2

## Quick Start

```ruby

# CocoaPods
pod 'ImageCropperKit'

# Carthage
github "cp110/ImageCropper"

```

## Usage

Crop faces from your image (UIImage or CGImage) in the easy way.

裁剪原图是 UIImage 或 CGImage

```Swift

// `type` in this method can be face, barcode, text or rectangle
// `padding` is the inside margin of the cropped image. default is .zero
// `type`：裁剪类型（人脸、条形码/二维码、文本、方框）
// `paddind`：裁剪出来的图片的内边距（可以使裁剪图片更完整些），默认 .zero
let image = UIImage(named: "image name")
// let image = UIImage(named: "image name")?.cgImage
image?.detector.crop(type: .face, padding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)) { [weak self] result in
    switch result {
        case .success(let cropImageResults): // cropImageResults: [(image: T, frame: CGRect)]
            // When the `Vision` successfully find type of object you set and successfuly crops it.
            print("Found")
        case .notFound(let image, let frame):// image: original image （原图）
            // When the image doesn't contain any type of object you did set, `result` will be `.notFound`.
            print("Not Found")
        case .failure(let image, let frame, let error): // image: original image （原图）
            // When the any error occured, `result` will be `failure`.
            print(error.localizedDescription)
        }
}
```

## Related Projects

- [FaceCropper](https://github.com/KimDarren/FaceCropper)
- [ImageDetect](https://github.com/Feghal/ImageDetect)

## Author

Arthur cp110：1107223894@qq.com

## License

ImageCropper is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
