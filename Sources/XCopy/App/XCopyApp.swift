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
    var body: some View {
        if let appIcon = NSImage(named: "AppIcon") {
            Image(nsImage: appIcon)
        } else {
            Image(systemName: "doc.on.clipboard")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
