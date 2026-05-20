import SwiftUI
import AppKit

@main
struct XCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanelView()
                .environmentObject(store)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)

        Window("远端配置", id: "hosts") {
            HostDetailView()
                .environmentObject(store)
                .frame(minWidth: 640, minHeight: 380)
        }
        .defaultSize(width: 720, height: 420)
        .commands {
            CommandMenu("XCopy") {
                Button("打开远端配置") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

private struct MenuBarIcon: View {
    private static let iconSize = NSSize(width: 16, height: 16)

    var body: some View {
        if let appIcon = NSImage(named: "AppIcon")?.menuBarSized(to: Self.iconSize) {
            Image(nsImage: appIcon)
                .accessibilityLabel("XCopy")
        } else {
            Image(systemName: "doc.on.clipboard")
                .imageScale(.small)
                .accessibilityLabel("XCopy")
        }
    }
}

private extension NSImage {
    func menuBarSized(to size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: size),
             from: NSRect(origin: .zero, size: self.size),
             operation: .sourceOver,
             fraction: 1)
        image.unlockFocus()
        image.size = size
        image.isTemplate = false
        return image
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
