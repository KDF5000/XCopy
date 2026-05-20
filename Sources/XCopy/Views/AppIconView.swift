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

        guard let context = NSGraphicsContext.current?.cgContext else {
            return image
        }

        context.clear(CGRect(origin: .zero, size: targetSize))
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        let scale = pointSize / 16

        func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
            CGRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
        }

        func roundedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, radius: CGFloat) -> NSBezierPath {
            NSBezierPath(roundedRect: rect(x, y, width, height), xRadius: radius * scale, yRadius: radius * scale)
        }

        NSColor.black.withAlphaComponent(0.55).setStroke()
        let lineWidth = max(1.2, 1.45 * scale)

        let backDocument = roundedRect(3.1, 2.2, 6.5, 9.2, radius: 1.6)
        backDocument.lineWidth = lineWidth
        backDocument.stroke()

        NSColor.black.setStroke()
        let frontDocument = roundedRect(5.2, 1.3, 7.2, 10.4, radius: 1.7)
        frontDocument.lineWidth = lineWidth
        frontDocument.stroke()

        for y in [4.2, 6.2, 8.2] {
            let line = NSBezierPath()
            line.move(to: CGPoint(x: 7.0 * scale, y: y * scale))
            line.line(to: CGPoint(x: 10.7 * scale, y: y * scale))
            line.lineCapStyle = .round
            line.lineWidth = lineWidth
            line.stroke()
        }

        let terminalRect = roundedRect(2.5, 9.8, 7.4, 3.9, radius: 1.2)
        NSColor.black.setFill()
        terminalRect.fill()

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .clear

        let prompt = NSBezierPath()
        prompt.move(to: CGPoint(x: 4.1 * scale, y: 10.9 * scale))
        prompt.line(to: CGPoint(x: 5.2 * scale, y: 11.75 * scale))
        prompt.line(to: CGPoint(x: 4.1 * scale, y: 12.6 * scale))
        prompt.lineCapStyle = .round
        prompt.lineJoinStyle = .round
        prompt.lineWidth = max(1, 1.1 * scale)
        prompt.stroke()

        let cursor = NSBezierPath()
        cursor.move(to: CGPoint(x: 6.3 * scale, y: 12.55 * scale))
        cursor.line(to: CGPoint(x: 8.0 * scale, y: 12.55 * scale))
        cursor.lineCapStyle = .round
        cursor.lineWidth = max(1, 1.1 * scale)
        cursor.stroke()

        NSGraphicsContext.restoreGraphicsState()

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
