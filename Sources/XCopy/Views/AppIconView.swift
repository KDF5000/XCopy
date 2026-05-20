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
        Canvas { context, size in
            let scale = min(size.width, size.height) / 16
            let iconRect = CGRect(
                x: (size.width - 16 * scale) / 2,
                y: (size.height - 16 * scale) / 2,
                width: 16 * scale,
                height: 16 * scale
            )

            func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
                CGRect(
                    x: iconRect.minX + x * scale,
                    y: iconRect.minY + y * scale,
                    width: width * scale,
                    height: height * scale
                )
            }

            let color = Color.primary
            let lineWidth = max(1.2, 1.45 * scale)

            let backDocument = Path(roundedRect: rect(3.1, 2.2, 6.5, 9.2), cornerRadius: 1.6 * scale)
            context.stroke(backDocument, with: .color(color.opacity(0.55)), lineWidth: lineWidth)

            let frontDocument = Path(roundedRect: rect(5.2, 1.3, 7.2, 10.4), cornerRadius: 1.7 * scale)
            context.stroke(frontDocument, with: .color(color), lineWidth: lineWidth)

            for y in [4.2, 6.2, 8.2] {
                var line = Path()
                line.move(to: CGPoint(x: iconRect.minX + 7.0 * scale, y: iconRect.minY + y * scale))
                line.addLine(to: CGPoint(x: iconRect.minX + 10.7 * scale, y: iconRect.minY + y * scale))
                context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }

            let terminalRect = Path(roundedRect: rect(2.5, 9.8, 7.4, 3.9), cornerRadius: 1.2 * scale)
            context.fill(terminalRect, with: .color(color))

            var prompt = Path()
            prompt.move(to: CGPoint(x: iconRect.minX + 4.1 * scale, y: iconRect.minY + 10.9 * scale))
            prompt.addLine(to: CGPoint(x: iconRect.minX + 5.2 * scale, y: iconRect.minY + 11.75 * scale))
            prompt.addLine(to: CGPoint(x: iconRect.minX + 4.1 * scale, y: iconRect.minY + 12.6 * scale))
            context.stroke(prompt, with: .color(.white), style: StrokeStyle(lineWidth: max(1, 1.1 * scale), lineCap: .round, lineJoin: .round))

            var cursor = Path()
            cursor.move(to: CGPoint(x: iconRect.minX + 6.3 * scale, y: iconRect.minY + 12.55 * scale))
            cursor.addLine(to: CGPoint(x: iconRect.minX + 8.0 * scale, y: iconRect.minY + 12.55 * scale))
            context.stroke(cursor, with: .color(.white), style: StrokeStyle(lineWidth: max(1, 1.1 * scale), lineCap: .round))
        }
        .frame(width: pointSize, height: pointSize)
        .accessibilityLabel("XCopy")
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
