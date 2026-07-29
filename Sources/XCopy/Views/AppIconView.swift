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

        // Build as a stencil (template) icon: black filled regions are the foreground,
        // transparent areas let the menu bar show through (matching the look of other
        // macOS menu bar icons). The white clipboard body becomes a transparent cutout.
        let outer = roundedRect(1.1, 1.1, 13.8, 13.8, radius: 3.2)
        let clipboardBody = roundedRect(5.1, 3.2, 6.6, 9.2, radius: 1.3)
        outer.append(clipboardBody)
        outer.windingRule = .evenOdd

        let clip = roundedRect(6.7, 10.5, 3.4, 1.0, radius: 0.5)
        let text = roundedRect(6.8, 6.4, 3.2, 1.2, radius: 0.6)

        NSColor.black.setFill()
        outer.fill()
        clip.fill()
        text.fill()

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
