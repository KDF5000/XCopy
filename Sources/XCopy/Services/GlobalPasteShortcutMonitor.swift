import AppKit
import ApplicationServices
import Foundation

final class GlobalPasteShortcutMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var onPasteShortcut: ((UUID) -> Void)?
    private var suppressNextPaste = false
    private var hostMatchers: [(id: UUID, strictTokens: [String], looseTokens: [String])] = []
    private var pasteShortcut = PasteShortcut.defaultShortcut
    private let sessionRegistry = XCopySessionRegistry()

    var isRunning: Bool {
        eventTap != nil
    }

    var hasAccessibilityPermission: Bool {
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func updateHosts(_ hosts: [RemoteHost]) {
        hostMatchers = hosts.map { host in
            (host.id, host.strictMatchTokens, host.looseMatchTokens)
        }
    }

    func updateShortcut(_ shortcut: PasteShortcut) {
        pasteShortcut = shortcut
    }

    func start(promptForPermission: Bool, onPasteShortcut: @escaping (UUID) -> Void) -> Bool {
        self.onPasteShortcut = onPasteShortcut

        guard eventTap == nil else {
            return true
        }

        let options = ["AXTrustedCheckOptionPrompt": promptForPermission] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            return false
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.eventCallback,
            userInfo: refcon
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        onPasteShortcut = nil
    }

    func pasteIntoFocusedApp() {
        suppressNextPaste = true

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func handle(event type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        if suppressNextPaste {
            suppressNextPaste = false
            return Unmanaged.passUnretained(event)
        }

        guard isPasteShortcut(event) else {
            return Unmanaged.passUnretained(event)
        }

        guard ClipboardImageService().hasImage() else {
            return Unmanaged.passUnretained(event)
        }

        guard let hostID = matchingHostIDForFocusedWindow() else {
            return Unmanaged.passUnretained(event)
        }

        onPasteShortcut?(hostID)
        return nil
    }

    private func isPasteShortcut(_ event: CGEvent) -> Bool {
        pasteShortcut.matches(event)
    }

    private func matchingHostIDForFocusedWindow() -> UUID? {
        if let tty = focusedTerminalTTY(),
           let target = sessionRegistry.target(forTTY: tty),
           let hostID = matchingHostID(for: target) {
            return hostID
        }

        let text = focusedWindowSearchText()
        guard !text.isEmpty else { return nil }

        return matchingHostID(for: text)
    }

    private func matchingHostID(for text: String) -> UUID? {
        let normalizedText = text.lowercased()

        if let strictMatch = hostMatchers.first(where: { matcher in
            matcher.strictTokens.contains { token in
                normalizedText.contains(token)
            }
        })?.id {
            return strictMatch
        }

        return hostMatchers.first { matcher in
            matcher.looseTokens.contains { token in
                normalizedText.contains(token)
            }
        }?.id
    }

    private func focusedTerminalTTY() -> String? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = app.bundleIdentifier else {
            return nil
        }

        switch bundleIdentifier {
        case "com.apple.Terminal":
            return runAppleScript("""
            tell application id "com.apple.Terminal"
              if not (exists front window) then return ""
              return tty of selected tab of front window
            end tell
            """)
        case "com.googlecode.iterm2":
            return runAppleScript("""
            tell application id "com.googlecode.iterm2"
              if not (exists current window) then return ""
              return tty of current session of current window
            end tell
            """)
        default:
            return nil
        }
    }

    private func runAppleScript(_ script: String) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return output?.isEmpty == false ? output : nil
    }

    private func focusedWindowSearchText() -> String {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return ""
        }

        var parts: [String] = [
            app.localizedName ?? "",
            app.bundleIdentifier ?? ""
        ]

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var focusedWindow: CFTypeRef?

        if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
           let focusedWindow {
            let window = focusedWindow as! AXUIElement
            var title: CFTypeRef?
            if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title) == .success,
               let titleString = title as? String {
                parts.append(titleString)
            }
        }

        return parts
            .joined(separator: " ")
            .lowercased()
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<GlobalPasteShortcutMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        return monitor.handle(event: type, event: event)
    }
}
