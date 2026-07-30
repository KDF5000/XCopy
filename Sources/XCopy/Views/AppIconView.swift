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

struct MenuBarIconView: View {
    let pointSize: CGFloat

    var body: some View {
        Image(nsImage: NSImage.xcopyMenuBarIcon(pointSize: pointSize))
            .resizable()
            .interpolation(.high)
            .frame(width: pointSize, height: pointSize)
            .accessibilityLabel("XCopy")
    }
}

private extension NSImage {
    static func xcopyMenuBarIcon(pointSize: CGFloat) -> NSImage {
        let targetSize = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: targetSize)
        image.lockFocus()
        defer {
            image.unlockFocus()
            image.size = targetSize
            image.isTemplate = true
        }

        let scale = pointSize / 16

        func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
            CGRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
        }

        func roundedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, radius: CGFloat) -> NSBezierPath {
            NSBezierPath(roundedRect: rect(x, y, width, height), xRadius: radius * scale, yRadius: radius * scale)
        }

        // Outer rounded rectangle (the "card" background of the icon).
        // As a template image, opaque black pixels here become the foreground color
        // (black on light menu bar, white on dark menu bar).
        NSColor.black.setFill()
        roundedRect(1.1, 1.1, 13.8, 13.8, radius: 3.2).fill()

        // Semi-transparent fill for the clipboard body — mimics the Mira-style
        // "filled outline" look where the inside is not fully transparent but a
        // lighter shade. For template images we express this via alpha on black:
        // the system renders low-alpha pixels as a tint of the foreground color.
        NSColor.black.withAlphaComponent(0.15).setFill()
        roundedRect(5.1, 3.2, 6.6, 9.2, radius: 1.3).fill()

        // Solid foreground details: the clip and the two text bars.
        NSColor.black.setFill()
        roundedRect(6.7, 10.5, 3.4, 1.0, radius: 0.5).fill()
        roundedRect(6.8, 6.4, 3.2, 1.2, radius: 0.6).fill()
        roundedRect(6.8, 8.2, 3.2, 1.2, radius: 0.6).fill()

        return image
    }

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
