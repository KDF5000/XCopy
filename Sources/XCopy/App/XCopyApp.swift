import SwiftUI
import AppKit

@main
struct XCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()

    var body: some Scene {
        MenuBarExtra("XCopy", systemImage: "doc.on.clipboard") {
            MenuBarPanelView()
                .environmentObject(store)
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
