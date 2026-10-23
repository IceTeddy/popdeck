import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Store a bounded PNG thumbnail with the item so the source file can move safely.
enum CustomIconImage {
    static let pixelLimit = 128
    static let dataLimit = 96 * 1024
    static let sourceLimit = 25 * 1024 * 1024

    enum ImportError: LocalizedError {
        case tooLarge, unreadable
        var errorDescription: String? {
            switch self {
            case .tooLarge: ProText.t("请选择小于 25 MB 的图片。", "Choose an image smaller than 25 MB.")
            case .unreadable: ProText.t("无法读取此图片，请尝试 PNG、JPEG、HEIC、TIFF 或 ICNS 图片。", "Unable to read this image. Try PNG, JPEG, HEIC, TIFF or ICNS.")
            }
        }
    }

    static func importFile(at url: URL) throws -> Data {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else { throw ImportError.unreadable }
        guard let count = values.fileSize, count <= sourceLimit else { throw ImportError.tooLarge }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            throw ImportError.unreadable
        }
        return try thumbnail(from: source)
    }

    static func thumbnail(from source: CGImageSource) throws -> Data {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelLimit,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        var index = 0
        if CGImageSourceGetType(source) as String? == "com.apple.icns" {
            var largest = 0
            for candidate in 0..<CGImageSourceGetCount(source) {
                let properties = CGImageSourceCopyPropertiesAtIndex(source, candidate, nil) as? [CFString: Any]
                let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
                if width > largest { largest = width; index = candidate }
            }
        }
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary) else {
            throw ImportError.unreadable
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
            throw ImportError.unreadable
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination), output.length <= dataLimit else { throw ImportError.unreadable }
        return output as Data
    }

    static func isValid(_ data: Data) -> Bool { decodedImage(data) != nil }

    static func decodedImage(_ data: Data) -> CGImage? {
        guard !data.isEmpty, data.count <= dataLimit,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetType(source) as String? == UTType.png.identifier,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= pixelLimit, height <= pixelLimit else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

@MainActor
final class CustomIconImageCache {
    static let shared = CustomIconImageCache()
    private let images = NSCache<NSData, NSImage>()
    private init() { images.totalCostLimit = 16 * 1024 * 1024 }

    func image(for data: Data) -> NSImage? {
        let key = data as NSData
        if let cached = images.object(forKey: key) { return cached }
        guard let bitmap = CustomIconImage.decodedImage(data) else { return nil }
        let image = NSImage(cgImage: bitmap, size: NSSize(width: bitmap.width, height: bitmap.height))
        images.setObject(image, forKey: key, cost: bitmap.width * bitmap.height * 4)
        return image
    }
}
