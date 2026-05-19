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
        NSImage(pasteboard: NSPasteboard.general) != nil
    }

    func writeClipboardImageToTemporaryFile() throws -> TemporaryImageFile {
        let pasteboard = NSPasteboard.general
        guard let image = NSImage(pasteboard: pasteboard) else {
            throw ClipboardImageError.noImage
        }

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw ClipboardImageError.cannotCreateImageData
        }

        let fileName = "xcopy-\(Self.timestamp()).png"
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("XCopy", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try pngData.write(to: url, options: .atomic)
        return TemporaryImageFile(url: url, fileName: fileName)
    }

    func copyString(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: Date())
    }
}
