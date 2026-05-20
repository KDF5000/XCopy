import AppKit
import SwiftUI

struct AppIconView: View {
    let pointSize: CGFloat

    var body: some View {
        if let appIcon = NSImage(named: "AppIcon")?.renderedAppIcon(at: pointSize) {
            Image(nsImage: appIcon)
                .resizable()
                .interpolation(.high)
                .frame(width: pointSize, height: pointSize)
                .accessibilityLabel("XCopy")
        } else {
            Image(systemName: "doc.on.clipboard")
                .resizable()
                .scaledToFit()
                .frame(width: pointSize, height: pointSize)
                .accessibilityLabel("XCopy")
        }
    }
}

private extension NSImage {
    func renderedAppIcon(at pointSize: CGFloat) -> NSImage {
        let targetSize = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: targetSize)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: targetSize),
             from: NSRect(origin: .zero, size: size),
             operation: .sourceOver,
             fraction: 1)
        image.unlockFocus()
        image.size = targetSize
        image.isTemplate = false
        return image
    }
}
