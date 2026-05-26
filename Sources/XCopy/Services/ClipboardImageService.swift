import AppKit
import Foundation

struct TemporaryImageFile {
    let url: URL
    let fileName: String
}

enum ClipboardImageError: LocalizedError {
    case noImage
    case cannotCreateImageData

    var errorDescription: String? {
        switch self {
        case .noImage:
            "剪贴板里没有可复制的图片。"
        case .cannotCreateImageData:
            "无法把剪贴板图片转换为 PNG 文件。"
        }
    }
}

struct ClipboardImageService {
    func hasImage() -> Bool {
        let hasImage = NSImage(pasteboard: NSPasteboard.general) != nil
        AppLog.clipboard.info("clipboard image check result=\(hasImage, privacy: .public)")
        return hasImage
    }

    func writeClipboardImageToTemporaryFile() throws -> TemporaryImageFile {
        let pasteboard = NSPasteboard.general
        guard let image = NSImage(pasteboard: pasteboard) else {
            AppLog.clipboard.error("clipboard image export failed: no image")
            throw ClipboardImageError.noImage
        }

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            AppLog.clipboard.error("clipboard image export failed: could not create PNG data")
            throw ClipboardImageError.cannotCreateImageData
        }

        let fileName = "xcopy-\(Self.timestamp()).png"
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("XCopy", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try pngData.write(to: url, options: .atomic)
        AppLog.clipboard.info("clipboard image written path=\(url.path, privacy: .public) bytes=\(pngData.count, privacy: .public)")
        return TemporaryImageFile(url: url, fileName: fileName)
    }

    func copyString(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        AppLog.clipboard.info("clipboard string updated value=\(string, privacy: .public)")
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: Date())
    }
}
