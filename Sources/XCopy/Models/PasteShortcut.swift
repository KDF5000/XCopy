import AppKit
import Foundation

struct PasteShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt
    var keyLabel: String

    static let defaultShortcut = PasteShortcut(
        keyCode: 9,
        modifiers: UInt((NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue) & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue),
        keyLabel: "V"
    )

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: UInt(modifiers))
    }

    var displayParts: [String] {
        var parts: [String] = []
        let flags = modifierFlags

        if flags.contains(.control) {
            parts.append("⌃")
        }
        if flags.contains(.option) {
            parts.append("⌥")
        }
        if flags.contains(.shift) {
            parts.append("⇧")
        }
        if flags.contains(.command) {
            parts.append("⌘")
        }

        parts.append(keyLabel.uppercased())
        return parts
    }

    static func from(event: NSEvent) -> PasteShortcut? {
        let relevantFlags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard relevantFlags.contains(.command) || relevantFlags.contains(.control) || relevantFlags.contains(.option) else {
            return nil
        }

        if event.keyCode == 9, relevantFlags == .command {
            return nil
        }

        guard let label = event.charactersIgnoringModifiers?.uppercased(), !label.isEmpty else {
            return nil
        }

        let rawModifiers = UInt(relevantFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
        return PasteShortcut(keyCode: event.keyCode, modifiers: rawModifiers, keyLabel: label)
    }

    func matches(_ event: CGEvent) -> Bool {
        let eventKeyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        guard eventKeyCode == keyCode else { return false }

        let eventFlags = event.flags
        let expectedFlags = modifierFlags

        return eventFlags.contains(.maskCommand) == expectedFlags.contains(.command)
            && eventFlags.contains(.maskControl) == expectedFlags.contains(.control)
            && eventFlags.contains(.maskAlternate) == expectedFlags.contains(.option)
            && eventFlags.contains(.maskShift) == expectedFlags.contains(.shift)
    }
}
