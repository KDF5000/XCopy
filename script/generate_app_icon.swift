#!/usr/bin/env swift

import AppKit
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first ?? "dist/AppIcon.icns"
let outputURL = URL(fileURLWithPath: outputPath)
let fileManager = FileManager.default
let temporaryDirectory = fileManager.temporaryDirectory.appendingPathComponent("XCopyIcon-\(UUID().uuidString)", isDirectory: true)
let iconsetURL = temporaryDirectory.appendingPathComponent("XCopy.iconset", isDirectory: true)

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

struct IconVariant {
    let points: Int
    let scale: Int

    var pixels: Int { points * scale }
    var fileName: String {
        scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
    }
}

let variants = [
    IconVariant(points: 16, scale: 1),
    IconVariant(points: 16, scale: 2),
    IconVariant(points: 32, scale: 1),
    IconVariant(points: 32, scale: 2),
    IconVariant(points: 128, scale: 1),
    IconVariant(points: 128, scale: 2),
    IconVariant(points: 256, scale: 1),
    IconVariant(points: 256, scale: 2),
    IconVariant(points: 512, scale: 1),
    IconVariant(points: 512, scale: 2)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()

    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawIcon(pixels: Int, to url: URL) throws {
    let size = CGFloat(pixels)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "XCopyIcon", code: 1)
    }

    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    defer { NSGraphicsContext.restoreGraphicsState() }

    guard let context = NSGraphicsContext.current?.cgContext else {
        throw NSError(domain: "XCopyIcon", code: 2)
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    context.clear(canvas)

    let inset = size * 0.06
    let appRect = canvas.insetBy(dx: inset, dy: inset)
    let corner = size * 0.22

    let background = NSBezierPath(roundedRect: appRect, xRadius: corner, yRadius: corner)
    NSGradient(colors: [
        color(0, 122, 255),
        color(0, 86, 210)
    ])?.draw(in: background, angle: -45)

    color(255, 255, 255, 0.28).setStroke()
    background.lineWidth = max(1, size * 0.012)
    background.stroke()

    let shadow = NSShadow()
    shadow.shadowColor = color(0, 34, 92, 0.22)
    shadow.shadowBlurRadius = size * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.015)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()

    let back = CGRect(x: size * 0.25, y: size * 0.30, width: size * 0.36, height: size * 0.48)
    drawRoundedRect(back, radius: size * 0.045, fill: color(214, 235, 255), stroke: color(255, 255, 255, 0.65), lineWidth: size * 0.012)

    let front = CGRect(x: size * 0.36, y: size * 0.20, width: size * 0.40, height: size * 0.52)
    drawRoundedRect(front, radius: size * 0.05, fill: color(255, 255, 255), stroke: color(207, 230, 255), lineWidth: size * 0.012)

    NSGraphicsContext.restoreGraphicsState()

    color(0, 122, 255).setStroke()
    let lineWidth = max(2, size * 0.035)
    for y in [0.57, 0.48, 0.39] {
        let line = NSBezierPath()
        line.move(to: CGPoint(x: size * 0.43, y: size * y))
        line.line(to: CGPoint(x: size * 0.67, y: size * y))
        line.lineCapStyle = .round
        line.lineWidth = lineWidth
        line.stroke()
    }

    let terminalRect = CGRect(x: size * 0.23, y: size * 0.18, width: size * 0.39, height: size * 0.19)
    drawRoundedRect(terminalRect, radius: size * 0.045, fill: color(13, 30, 53), stroke: color(255, 255, 255, 0.18), lineWidth: max(1, size * 0.008))

    color(94, 234, 212).setStroke()
    let prompt = NSBezierPath()
    prompt.move(to: CGPoint(x: size * 0.29, y: size * 0.275))
    prompt.line(to: CGPoint(x: size * 0.34, y: size * 0.235))
    prompt.line(to: CGPoint(x: size * 0.29, y: size * 0.195))
    prompt.lineCapStyle = .round
    prompt.lineJoinStyle = .round
    prompt.lineWidth = max(1.5, size * 0.022)
    prompt.stroke()

    color(94, 234, 212).setStroke()
    let cursor = NSBezierPath()
    cursor.move(to: CGPoint(x: size * 0.40, y: size * 0.205))
    cursor.line(to: CGPoint(x: size * 0.50, y: size * 0.205))
    cursor.lineCapStyle = .round
    cursor.lineWidth = max(1.5, size * 0.022)
    cursor.stroke()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "XCopyIcon", code: 3)
    }

    try pngData.write(to: url)
}

for variant in variants {
    try drawIcon(pixels: variant.pixels, to: iconsetURL.appendingPathComponent(variant.fileName))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

try? fileManager.removeItem(at: temporaryDirectory)

guard process.terminationStatus == 0 else {
    throw NSError(domain: "XCopyIcon", code: Int(process.terminationStatus))
}
